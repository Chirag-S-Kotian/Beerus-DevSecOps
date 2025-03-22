"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteFile = exports.updateFile = exports.getFileById = exports.getFiles = exports.uploadFile = void 0;
const cloudinary_1 = __importDefault(require("../config/cloudinary"));
const prisma_1 = __importDefault(require("../config/prisma"));
const fs_1 = __importDefault(require("fs"));
// Upload a new file
const uploadFile = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    console.log("Upload file endpoint hit");
    try {
        const { name } = req.body;
        const file = req.file;
        if (!file) {
            res.status(400).json({ message: 'No file provided' });
            return;
        }
        // Upload to Cloudinary
        const result = yield cloudinary_1.default.uploader.upload(file.path);
        fs_1.default.unlinkSync(file.path); // Remove the file from the server after uploading
        // Create new file entry in Prisma
        const newFile = yield prisma_1.default.file.create({
            data: {
                name: name,
                url: result.secure_url,
                userId: req.userId,
            },
        });
        res.status(201).json(newFile);
    }
    catch (error) {
        console.error("Upload file error:", error);
        res.status(500).json({ message: 'Server error' });
    }
});
exports.uploadFile = uploadFile;
// Get all files for a user
const getFiles = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const files = yield prisma_1.default.file.findMany({ where: { userId: req.userId } });
        res.status(200).json(files);
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});
exports.getFiles = getFiles;
// Get a file by ID
const getFileById = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const file = yield prisma_1.default.file.findUnique({ where: { id: req.params.id, userId: req.userId } });
        if (!file) {
            res.status(404).json({ message: 'File not found' });
            return;
        }
        res.status(200).json(file);
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});
exports.getFileById = getFileById;
// Update a file
const updateFile = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { name } = req.body;
        const file = yield prisma_1.default.file.update({
            where: { id: req.params.id, userId: req.userId },
            data: { name },
        });
        res.status(200).json(file);
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});
exports.updateFile = updateFile;
// Delete a file
const deleteFile = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const file = yield prisma_1.default.file.findUnique({ where: { id: req.params.id, userId: req.userId } });
        if (!file) {
            res.status(404).json({ message: 'File not found' });
            return;
        }
        const publicId = file.url.split('/').slice(-1)[0].split('.')[0];
        // Delete the file from Cloudinary using the public ID
        yield cloudinary_1.default.uploader.destroy(publicId);
        // Delete the file record from the database
        yield prisma_1.default.file.delete({ where: { id: file.id } });
        res.status(200).json({ message: 'File deleted successfully' });
    }
    catch (error) {
        console.error('Error deleting file:', error);
        res.status(500).json({ message: 'Server error' });
    }
});
exports.deleteFile = deleteFile;
