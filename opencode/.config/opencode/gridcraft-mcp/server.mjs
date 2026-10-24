#!/usr/bin/env node
//
// Self-contained GridCraft MCP server.
//
// Two backends, selected at startup:
//   1. If GridCraft is listening on its control channel (127.0.0.1:7979 by
//      default), speak the control protocol directly. This is the live GUI
//      workbook, so changes are visible immediately.
//   2. Otherwise, extract the gridcraft-cli binary that is bundled inside the
//      GridCraft AppImage and run its headless MCP engine. Nothing is kept in
//      ~/.local/bin and no helper script is required.
//
// The GridCraft AppImage is found at $GRIDCRAFT_APPIMAGE, then
// ~/AppImages/gridcraft.appimage, then any ~/AppImages/*gridcraft*.appimage.
// Set GRIDCRAFT_PORT to use a different control port, GRIDCRAFT_MODE to
// "direct" or "headless" to force a backend, and GRIDCRAFT_TIMEOUT to change
// the control-request timeout in milliseconds.

import fs from "node:fs";
import fsp from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import net from "node:net";
import readline from "node:readline";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const TOOLS = JSON.parse(fs.readFileSync(path.join(HERE, "tools.json"), "utf8"));

const HOST = "127.0.0.1";
const PORT = Number.parseInt(process.env.GRIDCRAFT_PORT || "7979", 10) || 7979;
const CONTROL_TIMEOUT =
    Number.parseInt(process.env.GRIDCRAFT_TIMEOUT || "120000", 10) || 120000;
const MODE = process.env.GRIDCRAFT_MODE;
const CACHE_DIR = path.join(
    process.env.XDG_CACHE_HOME || path.join(os.homedir(), ".cache"),
    "gridcraft-mcp",
);
const CLI_CACHE = path.join(CACHE_DIR, "gridcraft-cli");

const INSTRUCTIONS = `GridCraft is a spreadsheet app (an Excel clone). Cells use A1 notation ("B2", "A1:D10", "Sheet2!A1:B3"). Every action is a command: find ids and parameters with list_commands and run any of them with execute_command. Convenience tools cover the common flow: write_range / set_cell to enter values and formulas (strings starting with = are formulas), read_range / get_cell to read computed values back, format_range, create_table, insert_chart, sort_range, filter, evaluate_formula (try a formula without changing the sheet), undo / redo, open_workbook / save_workbook. inspect_workbook summarizes sheets, used ranges, tables, charts and names. list_functions lists the worksheet functions. Backend: connected to the GridCraft app at ${HOST}:${PORT}.`;

function log(message) {
    process.stderr.write(`[gridcraft-mcp] ${message}\n`);
}

// ── Control channel ──────────────────────────────────────────────────────────

function isPortOpen(port, timeout = 800) {
    return new Promise((resolve) => {
        const socket = net.createConnection({ host: HOST, port });
        let settled = false;
        const done = (open) => {
            if (settled) return;
            settled = true;
            socket.destroy();
            resolve(open);
        };
        socket.setTimeout(timeout, () => done(false));
        socket.once("connect", () => done(true));
        socket.once("error", () => done(false));
    });
}

class ControlClient {
    constructor(port) {
        this.port = port;
        this.socket = null;
        this.connecting = null;
        this.buffer = "";
        this.nextId = 0;
        this.pending = new Map();
        this.closed = false;
    }

    async connect() {
        if (this.closed) throw new Error("GridCraft control client is closed");
        if (this.socket && !this.socket.destroyed) return;
        if (this.connecting) return this.connecting;

        this.connecting = new Promise((resolve, reject) => {
            const socket = net.createConnection({ host: HOST, port: this.port });
            socket.setNoDelay(true);
            socket.setEncoding("utf8");

            const onError = (error) => {
                socket.destroy();
                reject(error);
            };
            socket.once("error", onError);
            socket.once("connect", () => {
                socket.off("error", onError);
                this.socket = socket;

                socket.on("data", (chunk) => this.onData(chunk));
                socket.on("error", (error) => this.failAll(error));
                socket.on("close", () => {
                    this.socket = null;
                    this.failAll(new Error("GridCraft control connection closed"));
                });
                resolve();
            });
        }).finally(() => {
            this.connecting = null;
        });

        return this.connecting;
    }

    onData(chunk) {
        this.buffer += chunk.toString("utf8");
        let newline;
        while ((newline = this.buffer.indexOf("\n")) !== -1) {
            const line = this.buffer.slice(0, newline).trim();
            this.buffer = this.buffer.slice(newline + 1);
            if (!line) continue;

            let message;
            try {
                message = JSON.parse(line);
            } catch {
                log(`ignoring malformed control response: ${line.slice(0, 200)}`);
                continue;
            }

            const request = this.pending.get(message.id);
            if (!request) continue;
            this.pending.delete(message.id);
            clearTimeout(request.timer);

            if (message.ok) request.resolve(message.result);
            else request.reject(new Error(message.error || "GridCraft control request failed"));
        }
    }

    failAll(error) {
        for (const request of this.pending.values()) {
            clearTimeout(request.timer);
            request.reject(error);
        }
        this.pending.clear();
    }

    async request(method, params = {}) {
        await this.connect();

        const id = ++this.nextId;
        return new Promise((resolve, reject) => {
            const timer = setTimeout(() => {
                this.pending.delete(id);
                reject(new Error(`GridCraft control request timed out after ${CONTROL_TIMEOUT}ms`));
            }, CONTROL_TIMEOUT);

            this.pending.set(id, { resolve, reject, timer });

            try {
                this.socket.write(`${JSON.stringify({ id, method, params })}\n`, (error) => {
                    if (!error) return;
                    this.pending.delete(id);
                    clearTimeout(timer);
                    reject(error);
                });
            } catch (error) {
                this.pending.delete(id);
                clearTimeout(timer);
                reject(error);
            }
        });
    }

    close() {
        this.closed = true;
        this.failAll(new Error("GridCraft control client closed"));
        if (this.socket) this.socket.destroy();
        this.socket = null;
    }
}

function pick(object, keys) {
    const result = {};
    for (const key of keys) {
        if (object[key] !== undefined) result[key] = object[key];
    }
    return result;
}

function execute(control, command, params) {
    return control.request("engine.execute", { command, params: params || {} });
}

const ALIGN_COMMANDS = {
    left: "home.alignLeft",
    center: "home.alignCenter",
    right: "home.alignRight",
    justify: "home.justify",
};

const FORMAT_KEYS = new Set([
    "bold",
    "italic",
    "underline",
    "fontName",
    "fontSize",
    "fontColor",
    "fillColor",
    "numberFormat",
    "horizontalAlign",
    "wrapText",
    "borders",
]);

function formatCommand(range, key, value) {
    switch (key) {
        case "bold":
            return { command: "home.bold", params: { range, on: Boolean(value) } };
        case "italic":
            return { command: "home.italic", params: { range, on: Boolean(value) } };
        case "underline":
            return { command: "home.underline", params: { range, on: Boolean(value) } };
        case "fontName":
            return { command: "home.fontName", params: { range, name: value } };
        case "fontSize":
            return { command: "home.fontSize", params: { range, size: value } };
        case "fontColor":
            return { command: "home.fontColor", params: { range, color: value } };
        case "fillColor":
            return { command: "home.fillColor", params: { range, color: value } };
        case "numberFormat":
            return { command: "home.numberFormat", params: { range, format: value } };
        case "horizontalAlign": {
            const command = ALIGN_COMMANDS[value];
            if (!command) throw new Error(`invalid horizontalAlign: ${value}`);
            return { command, params: { range } };
        }
        case "wrapText":
            return { command: "home.wrapText", params: { range, on: Boolean(value) } };
        case "borders":
            if (typeof value === "string") {
                return { command: "home.borders", params: { range, preset: value } };
            }
            if (value && typeof value === "object") {
                return { command: "home.borders", params: { range, ...value } };
            }
            throw new Error("borders must be a preset name or an object with a preset");
        default:
            throw new Error(`unknown format property: ${key}`);
    }
}

async function callTool(control, name, args) {
    switch (name) {
        case "execute_command":
            return execute(control, args.command, args.params ?? {});

        case "list_commands":
            return control.request("engine.commands", pick(args, ["search"]));

        case "inspect_workbook":
            return control.request("document.inspect", {});

        case "read_range":
            return control.request("sheet.read", pick(args, ["range", "sheet", "formulas", "formatted"]));

        case "write_range":
            return execute(control, "range.setValues", {
                range: args.range,
                values: args.values,
            });

        case "set_cell":
            return execute(control, "cell.set", { cell: args.cell, input: args.input });

        case "get_cell":
            return execute(control, "cell.get", { cell: args.cell });

        case "evaluate_formula":
            return execute(control, "formulas.evaluate", pick(args, ["formula", "cell"]));

        case "select":
            return execute(control, "selection.set", pick(args, ["range", "active"]));

        case "format_range": {
            for (const key of Object.keys(args)) {
                if (key !== "range" && !FORMAT_KEYS.has(key)) {
                    throw new Error(`unknown format property: ${key}`);
                }
            }

            const applied = [];
            for (const [key, value] of Object.entries(args)) {
                if (key === "range" || value === undefined) continue;
                const { command, params } = formatCommand(args.range, key, value);
                await execute(control, command, params);
                applied.push(command);
            }
            if (applied.length === 0) {
                throw new Error(
                    "nothing to apply: give at least one of bold, italic, underline, fontName, fontSize, fontColor, fillColor, numberFormat, horizontalAlign, wrapText, borders",
                );
            }
            return { applied, range: args.range };
        }

        case "create_table":
            return execute(control, "insert.table", pick(args, ["range", "header", "name", "style"]));

        case "insert_chart":
            return execute(control, "insert.chart", pick(args, ["range", "type", "at", "title", "subtype"]));

        case "sort_range":
            return execute(control, "data.sort", pick(args, ["keys", "range", "header"]));

        case "filter":
            return execute(
                control,
                "data.filterBy",
                pick(args, ["column", "range", "values", "custom", "top", "clear", "blanks"]),
            );

        case "open_workbook":
            return execute(control, "file.open", { path: args.path });

        case "save_workbook": {
            if (args.path === undefined) {
                const info = await control.request("document.inspect", {});
                if (!info.path) {
                    throw new Error(
                        'this workbook has never been saved: pass `path` (e.g. "/tmp/book.xlsx")',
                    );
                }
            }
            return execute(control, "file.save", pick(args, ["path"]));
        }

        case "new_workbook":
            return execute(control, "file.new", pick(args, ["sample"]));

        case "undo":
            return execute(control, "edit.undo", pick(args, ["steps"]));

        case "redo":
            return execute(control, "edit.redo", pick(args, ["steps"]));

        case "screenshot":
            return control.request("ui.screenshot", { path: args.path });

        case "list_functions":
            return execute(control, "formulas.functions", pick(args, ["search", "category"]));

        default:
            throw new Error(`unknown tool: ${name}`);
    }
}

// ── MCP stdio server (direct mode) ───────────────────────────────────────────

function send(message) {
    if (!process.stdout.writable) return;
    process.stdout.write(`${JSON.stringify(message)}\n`);
}

function sendError(id, code, message) {
    send({ jsonrpc: "2.0", id, error: { code, message } });
}

async function handleRequest(message, control) {
    const { id, method, params } = message;

    if (method === "initialize") {
        send({
            jsonrpc: "2.0",
            id,
            result: {
                capabilities: {
                    prompts: { listChanged: false },
                    resources: { listChanged: false, subscribe: false },
                    tools: { listChanged: false },
                },
                instructions: INSTRUCTIONS,
                protocolVersion: "2024-11-05",
                serverInfo: { name: "gridcraft", title: "GridCraft", version: "0.11.1" },
            },
        });
        return;
    }

    if (method === "ping") {
        send({ jsonrpc: "2.0", id, result: {} });
        return;
    }

    if (method === "tools/list") {
        send({ jsonrpc: "2.0", id, result: { tools: TOOLS } });
        return;
    }

    if (method === "tools/call") {
        const name = params?.name;
        const args = params?.arguments ?? {};
        try {
            const result = await callTool(control, name, args);
            send({
                jsonrpc: "2.0",
                id,
                result: {
                    content: [{ type: "text", text: JSON.stringify(result ?? null, null, 2) }],
                    isError: false,
                },
            });
        } catch (error) {
            const text = `${name}: ${error instanceof Error ? error.message : String(error)}`;
            send({
                jsonrpc: "2.0",
                id,
                result: {
                    content: [{ type: "text", text }],
                    isError: true,
                },
            });
        }
        return;
    }

    if (method === "prompts/list") {
        send({ jsonrpc: "2.0", id, result: { prompts: [] } });
        return;
    }

    if (method === "resources/list") {
        send({ jsonrpc: "2.0", id, result: { resources: [] } });
        return;
    }

    if (method === "resources/templates/list") {
        send({ jsonrpc: "2.0", id, result: { resourceTemplates: [] } });
        return;
    }

    if (method === "logging/setLevel") {
        send({ jsonrpc: "2.0", id, result: {} });
        return;
    }

    sendError(id, -32601, `Method not found: ${method}`);
}

function runDirect() {
    const control = new ControlClient(PORT);
    const input = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });
    let queue = Promise.resolve();

    input.on("line", (line) => {
        queue = queue.then(async () => {
            if (!line.trim()) return;

            let message;
            try {
                message = JSON.parse(line);
            } catch {
                sendError(null, -32700, "Parse error");
                return;
            }

            // Notifications (no id) do not get a response.
            if (message.id === undefined || message.id === null) return;

            try {
                await handleRequest(message, control);
            } catch (error) {
                log(`request failed: ${error instanceof Error ? error.message : String(error)}`);
                sendError(message.id, -32603, "Internal error");
            }
        });
    });

    input.on("close", () => {
        queue.finally(() => control.close());
    });

    process.stdout.on("error", () => {
        control.close();
        process.exit(0);
    });
}

// ── Headless mode (bundled gridcraft-cli) ────────────────────────────────────

async function exists(file) {
    try {
        await fsp.access(file, fs.constants.F_OK);
        return true;
    } catch {
        return false;
    }
}

async function findAppImage() {
    const explicit = [
        process.env.GRIDCRAFT_APPIMAGE,
        path.join(os.homedir(), "AppImages", "gridcraft.appimage"),
    ].filter(Boolean);

    for (const candidate of explicit) {
        try {
            await fsp.access(candidate, fs.constants.X_OK);
            return candidate;
        } catch {
            // Try the next candidate.
        }
    }

    const directory = path.join(os.homedir(), "AppImages");
    try {
        const entries = await fsp.readdir(directory);
        for (const entry of entries.sort()) {
            if (!/gridcraft.*\.appimage$/i.test(entry)) continue;
            const candidate = path.join(directory, entry);
            try {
                await fsp.access(candidate, fs.constants.X_OK);
                return candidate;
            } catch {
                // Keep looking.
            }
        }
    } catch {
        // ~/AppImages does not exist.
    }

    return null;
}

async function ensureCli() {
    const appimage = await findAppImage();
    const cached = await exists(CLI_CACHE);

    if (!appimage) {
        if (cached) {
            log("GridCraft AppImage not found; using cached gridcraft-cli");
            return CLI_CACHE;
        }
        throw new Error(
            "GridCraft AppImage not found. Set GRIDCRAFT_APPIMAGE to its path (for example ~/AppImages/gridcraft.appimage).",
        );
    }

    let needsExtract = !cached;
    if (!needsExtract) {
        const [appimageStat, cacheStat] = await Promise.all([
            fsp.stat(appimage),
            fsp.stat(CLI_CACHE),
        ]);
        needsExtract = appimageStat.mtimeMs > cacheStat.mtimeMs;
    }

    if (!needsExtract) return CLI_CACHE;

    await fsp.mkdir(CACHE_DIR, { recursive: true });
    const temporary = await fsp.mkdtemp(path.join(os.tmpdir(), "gridcraft-mcp-"));

    try {
        log(`extracting gridcraft-cli from ${appimage}`);
        await new Promise((resolve, reject) => {
            const child = spawn(appimage, ["--appimage-extract", "usr/bin/gridcraft-cli"], {
                cwd: temporary,
                stdio: ["ignore", "ignore", "pipe"],
            });
            let stderr = "";
            child.stderr.on("data", (chunk) => {
                if (stderr.length < 4000) stderr += chunk.toString("utf8");
            });
            child.once("error", reject);
            child.once("close", (code) => {
                if (code === 0) resolve();
                else reject(new Error(`AppImage extraction failed (exit ${code}): ${stderr.trim()}`));
            });
        });

        const extracted = path.join(temporary, "squashfs-root", "usr", "bin", "gridcraft-cli");
        const staging = `${CLI_CACHE}.new-${process.pid}`;
        await fsp.copyFile(extracted, staging);
        await fsp.chmod(staging, 0o755);
        await fsp.rename(staging, CLI_CACHE);
        return CLI_CACHE;
    } catch (error) {
        if (cached) {
            log(`extraction failed; using cached gridcraft-cli: ${error.message}`);
            return CLI_CACHE;
        }
        throw error;
    } finally {
        await fsp.rm(temporary, { recursive: true, force: true }).catch(() => {});
    }
}

async function runHeadless() {
    const cli = await ensureCli();
    log(`no GridCraft control channel on ${HOST}:${PORT}; using the headless engine`);

    const child = spawn(cli, ["mcp"], { stdio: ["pipe", "pipe", "inherit"] });

    child.stdin.on("error", () => {});
    child.stdout.on("error", () => {});
    child.stdout.pipe(process.stdout);
    process.stdin.pipe(child.stdin);

    const stop = (signal) => {
        try {
            child.kill(signal);
        } catch {
            // Already gone.
        }
    };
    process.on("SIGINT", () => stop("SIGINT"));
    process.on("SIGTERM", () => stop("SIGTERM"));

    child.once("error", (error) => {
        log(`failed to start gridcraft-cli: ${error.message}`);
        process.exit(1);
    });
    child.once("close", (code) => {
        process.exit(code ?? 1);
    });

    process.stdout.on("error", () => {
        stop("SIGTERM");
        process.exit(0);
    });
}

// ── Main ─────────────────────────────────────────────────────────────────────

// WordCraft and GridCraft both default to port 7979. Before bridging, make
// sure the listener is actually GridCraft and not the other app.
async function probeGridCraft(port) {
    const control = new ControlClient(port);
    let timer;
    try {
        const result = await Promise.race([
            control.request("document.inspect", {}),
            new Promise((_, reject) => {
                timer = setTimeout(
                    () => reject(new Error("GridCraft probe timed out")),
                    2000,
                );
            }),
        ]);
        return Boolean(result && Array.isArray(result.sheets));
    } catch {
        return false;
    } finally {
        clearTimeout(timer);
        control.close();
    }
}

async function main() {
    if (MODE !== "headless" && (MODE === "direct" || (await isPortOpen(PORT)))) {
        if (MODE === "direct" || (await probeGridCraft(PORT))) {
            log(`connected to the GridCraft control channel at ${HOST}:${PORT}`);
            runDirect();
            return;
        }
        log(`port ${PORT} is not a GridCraft control channel; using headless`);
    }

    await runHeadless();
}

main().catch((error) => {
    log(error instanceof Error ? error.message : String(error));
    process.exit(1);
});
