"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const fileController_1 = require("../controllers/fileController");
const authMiddleware_1 = __importDefault(require("../middlewares/authMiddleware"));
const multer_1 = __importDefault(require("../config/multer"));
const router = (0, express_1.Router)();
// Upload a new file (multer handles the file in `req.file`)
router.post('/upload', authMiddleware_1.default, multer_1.default.single('file'), fileController_1.uploadFile);
// Get all files for the authenticated user
router.get('/', authMiddleware_1.default, fileController_1.getFiles);
// Get a specific file by ID
router.get('/:id', authMiddleware_1.default, fileController_1.getFileById);
// Update a file (e.g., change metadata)
router.put('/:id', authMiddleware_1.default, fileController_1.updateFile);
// Delete a file
router.delete('/:id', authMiddleware_1.default, fileController_1.deleteFile);
exports.default = router;
