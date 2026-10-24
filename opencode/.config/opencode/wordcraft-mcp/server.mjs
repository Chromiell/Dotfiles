#!/usr/bin/env node
// WordCraft MCP launcher.
//
// WordCraft ships a complete MCP server inside its AppImage
// (`usr/bin/wordcraft-cli mcp`). This launcher locates the AppImage, extracts
// that CLI on first use, then hands stdio straight to it. It supports the same
// two backends as the GridCraft server:
//
//   direct   - WordCraft is listening on its control channel; operate on the
//              live GUI document.
//   headless - no GUI; run the bundled engine in-process.
//
// Nothing outside this file (and the extracted CLI cache) is required.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import net from "node:net";
import readline from "node:readline";
import { spawn, spawnSync } from "node:child_process";

const HOME = os.homedir();
const HOST = "127.0.0.1";
const PORT = Number.parseInt(process.env.WORDCRAFT_PORT ?? "7979", 10) || 7979;
const MODE = (process.env.WORDCRAFT_MODE ?? "auto").toLowerCase();
const CACHE_DIR = path.join(
    process.env.XDG_CACHE_HOME || path.join(HOME, ".cache"),
    "wordcraft-mcp",
);
const CLI_CACHE = path.join(CACHE_DIR, "wordcraft-cli");

function log(message) {
    process.stderr.write(`[wordcraft-mcp] ${message}\n`);
}

function isExecutable(file) {
    try {
        fs.accessSync(file, fs.constants.X_OK);
        return true;
    } catch {
        return false;
    }
}

function isFile(file) {
    try {
        return fs.statSync(file).isFile();
    } catch {
        return false;
    }
}

function findAppImage() {
    const explicit = process.env.WORDCRAFT_APPIMAGE;
    if (explicit) {
        if (isFile(explicit) && isExecutable(explicit)) return explicit;
        log(`WORDCRAFT_APPIMAGE is not an executable file: ${explicit}`);
    }

    const preferred = path.join(HOME, "AppImages", "wordcraft.appimage");
    if (isFile(preferred) && isExecutable(preferred)) return preferred;

    const dir = path.join(HOME, "AppImages");
    try {
        const match = fs
            .readdirSync(dir)
            .filter((name) => /wordcraft.*\.appimage$/i.test(name))
            .map((name) => path.join(dir, name))
            .find((file) => isFile(file) && isExecutable(file));
        if (match) return match;
    } catch {
        // ~/AppImages does not exist.
    }

    return null;
}

function findOnPath(name) {
    for (const dir of (process.env.PATH ?? "").split(path.delimiter)) {
        if (!dir) continue;
        const candidate = path.join(dir, name);
        if (isFile(candidate) && isExecutable(candidate)) return candidate;
    }
    return null;
}

function cacheIsFresh(cli, appImage) {
    if (!isFile(cli) || !isExecutable(cli)) return false;
    if (!appImage) return true;
    try {
        return fs.statSync(cli).mtimeMs >= fs.statSync(appImage).mtimeMs;
    } catch {
        return false;
    }
}

function extractCli(appImage) {
    fs.mkdirSync(CACHE_DIR, { recursive: true });
    const temp = fs.mkdtempSync(path.join(CACHE_DIR, "extract-"));

    try {
        log(`extracting wordcraft-cli from ${appImage}`);
        const result = spawnSync(
            appImage,
            ["--appimage-extract", "usr/bin/wordcraft-cli"],
            { cwd: temp, encoding: "utf8" },
        );

        const extracted = path.join(temp, "squashfs-root", "usr", "bin", "wordcraft-cli");
        if (result.status !== 0 || !isFile(extracted)) {
            const detail = (result.stderr || result.stdout || "").trim();
            throw new Error(
                `AppImage extraction failed${detail ? `: ${detail}` : ""}`,
            );
        }

        const staged = `${CLI_CACHE}.new-${process.pid}`;
        fs.copyFileSync(extracted, staged);
        fs.chmodSync(staged, 0o755);
        fs.renameSync(staged, CLI_CACHE);
        log(`cached wordcraft-cli at ${CLI_CACHE}`);
        return CLI_CACHE;
    } finally {
        fs.rmSync(temp, { recursive: true, force: true });
    }
}

function resolveCli() {
    const explicit = process.env.WORDCRAFT_CLI;
    if (explicit) {
        if (isFile(explicit) && isExecutable(explicit)) return explicit;
        log(`WORDCRAFT_CLI is not an executable file: ${explicit}`);
    }

    const appImage = findAppImage();
    if (cacheIsFresh(CLI_CACHE, appImage)) return CLI_CACHE;

    if (appImage) {
        try {
            return extractCli(appImage);
        } catch (error) {
            if (isFile(CLI_CACHE) && isExecutable(CLI_CACHE)) {
                log(`${error.message}; using cached CLI`);
                return CLI_CACHE;
            }
            log(error.message);
        }
    }

    const onPath = findOnPath("wordcraft-cli");
    if (onPath) return onPath;

    log(
        "no wordcraft-cli found: install the WordCraft AppImage in ~/AppImages, " +
            "or set WORDCRAFT_APPIMAGE or WORDCRAFT_CLI",
    );
    process.exit(127);
}

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

        socket.setTimeout(timeout);
        socket.once("connect", () => done(true));
        socket.once("timeout", () => done(false));
        socket.once("error", () => done(false));
    });
}

// WordCraft and GridCraft both default to port 7979. Before bridging, make
// sure the listener is actually WordCraft and not the other app.
function probeWordCraft(port) {
    let key = process.env.WORDCRAFT_CONTROL_KEY;
    if (!key) {
        const keyFile = path.join(
            HOME,
            ".config",
            "wordcraft",
            `control-key.local-${port}`,
        );
        try {
            key = fs.readFileSync(keyFile, "utf8").trim();
        } catch {
            return Promise.resolve(false);
        }
    }
    if (!key) return Promise.resolve(false);

    return new Promise((resolve) => {
        const socket = net.createConnection({ host: HOST, port });
        let buffer = "";
        let settled = false;

        const done = (ok) => {
            if (settled) return;
            settled = true;
            socket.destroy();
            resolve(ok);
        };

        socket.setTimeout(1500, () => done(false));
        socket.once("error", () => done(false));
        socket.once("connect", () => {
            socket.write(
                `${JSON.stringify({
                    id: 1,
                    key,
                    method: "document.inspect",
                    params: {},
                })}\n`,
            );
        });
        socket.on("data", (chunk) => {
            buffer += chunk.toString("utf8");
            const newline = buffer.indexOf("\n");
            if (newline === -1) return;

            try {
                const message = JSON.parse(buffer.slice(0, newline));
                if (message.id !== 1) return;
                done(Boolean(message.ok && Array.isArray(message.result?.blocks)));
            } catch {
                // Wait for the rest of the line.
            }
        });
    });
}

function headlessArgs() {
    const readRoot = process.env.WORDCRAFT_READ_ROOT || HOME;
    const writeRoot = process.env.WORDCRAFT_WRITE_ROOT || HOME;
    const args = [
        "mcp",
        "--automation-read-root",
        readRoot,
        "--automation-write-root",
        writeRoot,
    ];
    if (process.env.WORDCRAFT_AUTHOR) {
        args.push("--author", process.env.WORDCRAFT_AUTHOR);
    }
    return args;
}

// WordCraft 0.10.0's MCP server accepts `query` on list_commands but does not
// apply it. Filter the result here so a search does not return the full ~160 KB
// command catalogue to the model.
function filterCommands(text, query) {
    let commands;
    try {
        commands = JSON.parse(text);
    } catch {
        return text;
    }
    if (!Array.isArray(commands)) return text;

    const needle = query.toLowerCase();
    return JSON.stringify(
        commands.filter((command) =>
            [command?.id, command?.label, command?.location].some(
                (value) =>
                    typeof value === "string" &&
                    value.toLowerCase().includes(needle),
            ),
        ),
        null,
        2,
    );
}

// Forward MCP traffic between the client and wordcraft-cli. The CLI owns the
// protocol; the only interception is list_commands filtering.
function runProxy(child) {
    const pendingQueries = new Map();
    const input = readline.createInterface({
        input: process.stdin,
        crlfDelay: Infinity,
    });

    input.on("line", (line) => {
        if (!line.trim()) return;

        let message;
        try {
            message = JSON.parse(line);
        } catch {
            child.stdin.write(`${line}\n`);
            return;
        }

        if (
            message?.method === "tools/call" &&
            message.params?.name === "list_commands"
        ) {
            const query = message.params.arguments?.query;
            if (typeof query === "string" && query.trim()) {
                pendingQueries.set(message.id, query.trim());
                message.params.arguments = { ...message.params.arguments };
                delete message.params.arguments.query;
            }
        }

        child.stdin.write(`${JSON.stringify(message)}\n`);
    });

    input.on("close", () => {
        if (!child.stdin.destroyed) child.stdin.end();
    });

    const output = readline.createInterface({
        input: child.stdout,
        crlfDelay: Infinity,
    });

    output.on("line", (line) => {
        if (!line.trim()) return;

        let message;
        try {
            message = JSON.parse(line);
        } catch {
            process.stdout.write(`${line}\n`);
            return;
        }

        if (pendingQueries.has(message.id)) {
            const query = pendingQueries.get(message.id);
            pendingQueries.delete(message.id);
            for (const item of message.result?.content ?? []) {
                if (item?.type === "text" && typeof item.text === "string") {
                    item.text = filterCommands(item.text, query);
                }
            }
        }

        process.stdout.write(`${JSON.stringify(message)}\n`);
    });

    return () => {
        input.close();
        process.stdin.destroy();
    };
}

async function main() {
    const cli = resolveCli();

    let direct;
    if (MODE === "direct") {
        direct = true;
    } else if (MODE === "headless") {
        direct = false;
    } else {
        direct = await isPortOpen(PORT);
        if (direct && !(await probeWordCraft(PORT))) {
            log(`port ${PORT} is not a WordCraft control channel; using headless`);
            direct = false;
        }
    }

    const args = direct
        ? ["mcp", "--connect", `${HOST}:${PORT}`]
        : headlessArgs();

    if (direct) {
        log(`connecting to the WordCraft app at ${HOST}:${PORT}`);
    } else {
        log("starting headless session");
    }

    const child = spawn(cli, args, { stdio: ["pipe", "pipe", "inherit"] });
    const closeInput = runProxy(child);

    child.once("error", (error) => {
        log(`failed to start wordcraft-cli: ${error.message}`);
        process.exit(127);
    });

    child.once("exit", (code, signal) => {
        if (signal) {
            log(`wordcraft-cli terminated by ${signal}`);
        }
        process.exitCode = signal ? 1 : (code ?? 0);
        closeInput();
    });

    for (const signal of ["SIGINT", "SIGTERM", "SIGHUP"]) {
        process.on(signal, () => {
            if (!child.killed) child.kill(signal);
        });
    }
}

main().catch((error) => {
    log(error.stack || error.message);
    process.exit(1);
});
