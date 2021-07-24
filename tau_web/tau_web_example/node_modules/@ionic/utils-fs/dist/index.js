"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.walk = exports.Walker = exports.compilePaths = exports.tmpfilepath = exports.findBaseDirectory = exports.isExecutableFile = exports.pathExecutable = exports.pathWritable = exports.pathReadable = exports.pathExists = exports.pathAccessible = exports.writeStreamToFile = exports.cacheFileChecksum = exports.getFileChecksums = exports.getFileChecksum = exports.fileToString = exports.getFileTree = exports.readdirp = exports.readdirSafe = exports.statSafe = void 0;
const tslib_1 = require("tslib");
const fs = require("fs-extra");
const os = require("os");
const path = require("path");
const stream = require("stream");
const safe = require("./safe");
tslib_1.__exportStar(require("fs-extra"), exports);
var safe_1 = require("./safe");
Object.defineProperty(exports, "statSafe", { enumerable: true, get: function () { return safe_1.stat; } });
Object.defineProperty(exports, "readdirSafe", { enumerable: true, get: function () { return safe_1.readdir; } });
async function readdirp(dir, { filter, onError, walkerOptions } = {}) {
    return new Promise((resolve, reject) => {
        const items = [];
        let rs = walk(dir, walkerOptions);
        if (filter) {
            rs = rs.pipe(new stream.Transform({
                objectMode: true,
                transform(obj, enc, cb) {
                    if (!filter || filter(obj)) {
                        this.push(obj);
                    }
                    cb();
                },
            }));
        }
        rs
            .on('error', (err) => onError ? onError(err) : reject(err))
            .on('data', (item) => items.push(item.path))
            .on('end', () => resolve(items));
    });
}
exports.readdirp = readdirp;
/**
 * Compile and return a file tree structure.
 *
 * This function walks a directory structure recursively, building a nested
 * object structure in memory that represents it. When finished, the root
 * directory node is returned.
 *
 * @param dir The root directory from which to compile the file tree
 */
async function getFileTree(dir, { onError, onFileNode = n => n, onDirectoryNode = n => n, walkerOptions } = {}) {
    const fileMap = new Map([]);
    const getOrCreateParent = (item) => {
        const parentPath = path.dirname(item.path);
        const parent = fileMap.get(parentPath);
        if (parent && parent.type === "directory" /* DIRECTORY */) {
            return parent;
        }
        return onDirectoryNode({ path: parentPath, type: "directory" /* DIRECTORY */, children: [] });
    };
    const createFileNode = (item, parent) => {
        const node = { path: item.path, parent };
        return item.stats.isDirectory() ?
            onDirectoryNode({ ...node, type: "directory" /* DIRECTORY */, children: [] }) :
            onFileNode({ ...node, type: "file" /* FILE */ });
    };
    return new Promise((resolve, reject) => {
        dir = path.resolve(dir);
        const rs = walk(dir, walkerOptions);
        rs
            .on('error', err => onError ? onError(err) : reject(err))
            .on('data', item => {
            const parent = getOrCreateParent(item);
            const node = createFileNode(item, parent);
            parent.children.push(node);
            fileMap.set(item.path, node);
            fileMap.set(parent.path, parent);
        })
            .on('end', () => {
            const root = fileMap.get(dir);
            if (!root) {
                return reject(new Error('No root node found after walking directory structure.'));
            }
            delete root.parent;
            resolve(root);
        });
    });
}
exports.getFileTree = getFileTree;
async function fileToString(filePath) {
    try {
        return await fs.readFile(filePath, { encoding: 'utf8' });
    }
    catch (e) {
        if (e.code === 'ENOENT' || e.code === 'ENOTDIR') {
            return '';
        }
        throw e;
    }
}
exports.fileToString = fileToString;
async function getFileChecksum(filePath) {
    const crypto = await Promise.resolve().then(() => require('crypto'));
    return new Promise((resolve, reject) => {
        const hash = crypto.createHash('md5');
        const input = fs.createReadStream(filePath);
        input.on('error', (err) => {
            reject(err);
        });
        hash.once('readable', () => {
            const fullChecksum = hash.read().toString('hex');
            resolve(fullChecksum);
        });
        input.pipe(hash);
    });
}
exports.getFileChecksum = getFileChecksum;
/**
 * Return true and cached checksums for a file by its path.
 *
 * Cached checksums are stored as `.md5` files next to the original file. If
 * the cache file is missing, the cached checksum is undefined.
 *
 * @param p The file path
 * @return Promise<[true checksum, cached checksum or undefined if cache file missing]>
 */
async function getFileChecksums(p) {
    return Promise.all([
        getFileChecksum(p),
        (async () => {
            try {
                const md5 = await fs.readFile(`${p}.md5`, { encoding: 'utf8' });
                return md5.trim();
            }
            catch (e) {
                if (e.code !== 'ENOENT') {
                    throw e;
                }
            }
        })(),
    ]);
}
exports.getFileChecksums = getFileChecksums;
/**
 * Store a cache file containing the source file's md5 checksum hash.
 *
 * @param p The file path
 * @param checksum The checksum. If excluded, the checksum is computed
 */
async function cacheFileChecksum(p, checksum) {
    const md5 = await getFileChecksum(p);
    await fs.writeFile(`${p}.md5`, md5, { encoding: 'utf8' });
}
exports.cacheFileChecksum = cacheFileChecksum;
function writeStreamToFile(stream, destination) {
    return new Promise((resolve, reject) => {
        const dest = fs.createWriteStream(destination);
        stream.pipe(dest);
        dest.on('error', reject);
        dest.on('finish', resolve);
    });
}
exports.writeStreamToFile = writeStreamToFile;
async function pathAccessible(filePath, mode) {
    try {
        await fs.access(filePath, mode);
    }
    catch (e) {
        return false;
    }
    return true;
}
exports.pathAccessible = pathAccessible;
async function pathExists(filePath) {
    return pathAccessible(filePath, fs.constants.F_OK);
}
exports.pathExists = pathExists;
async function pathReadable(filePath) {
    return pathAccessible(filePath, fs.constants.R_OK);
}
exports.pathReadable = pathReadable;
async function pathWritable(filePath) {
    return pathAccessible(filePath, fs.constants.W_OK);
}
exports.pathWritable = pathWritable;
async function pathExecutable(filePath) {
    return pathAccessible(filePath, fs.constants.X_OK);
}
exports.pathExecutable = pathExecutable;
async function isExecutableFile(filePath) {
    const [stats, executable] = await (Promise.all([
        safe.stat(filePath),
        pathExecutable(filePath),
    ]));
    return !!stats && (stats.isFile() || stats.isSymbolicLink()) && executable;
}
exports.isExecutableFile = isExecutableFile;
/**
 * Find the base directory based on the path given and a marker file to look for.
 */
async function findBaseDirectory(dir, file) {
    if (!dir || !file) {
        return;
    }
    for (const d of compilePaths(dir)) {
        const results = await safe.readdir(d);
        if (results.includes(file)) {
            return d;
        }
    }
}
exports.findBaseDirectory = findBaseDirectory;
/**
 * Generate a random file path within the computer's temporary directory.
 *
 * @param prefix Optionally provide a filename prefix.
 */
function tmpfilepath(prefix) {
    const rn = Math.random().toString(16).substring(2, 8);
    const p = path.resolve(os.tmpdir(), prefix ? `${prefix}-${rn}` : rn);
    return p;
}
exports.tmpfilepath = tmpfilepath;
/**
 * Given an absolute system path, compile an array of paths working backwards
 * one directory at a time, always ending in the root directory.
 *
 * For example, `'/some/dir'` => `['/some/dir', '/some', '/']`
 *
 * @param filePath Absolute system base path.
 */
function compilePaths(filePath) {
    filePath = path.normalize(filePath);
    if (!path.isAbsolute(filePath)) {
        throw new Error(`${filePath} is not an absolute path`);
    }
    const parsed = path.parse(filePath);
    if (filePath === parsed.root) {
        return [filePath];
    }
    return filePath
        .slice(parsed.root.length)
        .split(path.sep)
        .map((segment, i, array) => parsed.root + path.join(...array.slice(0, array.length - i)))
        .concat(parsed.root);
}
exports.compilePaths = compilePaths;
class Walker extends stream.Readable {
    constructor(p, options = {}) {
        super({ objectMode: true });
        this.p = p;
        this.options = options;
        this.paths = [this.p];
    }
    _read() {
        const p = this.paths.shift();
        const { pathFilter } = this.options;
        if (!p) {
            this.push(null);
            return;
        }
        fs.lstat(p, (err, stats) => {
            if (err) {
                this.emit('error', err);
                return;
            }
            const item = { path: p, stats };
            if (stats.isDirectory()) {
                fs.readdir(p, (err, contents) => {
                    if (err) {
                        this.emit('error', err);
                        return;
                    }
                    let paths = contents.map(file => path.join(p, file));
                    if (pathFilter) {
                        paths = paths.filter(p => pathFilter(p.substring(this.p.length + 1)));
                    }
                    this.paths.push(...paths);
                    this.push(item);
                });
            }
            else {
                this.push(item);
            }
        });
    }
}
exports.Walker = Walker;
function walk(p, options = {}) {
    return new Walker(p, options);
}
exports.walk = walk;
