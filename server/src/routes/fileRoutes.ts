import { Router } from 'express';
import {
  uploadFile,
  getFiles,
  getFileById,
  updateFile,
  deleteFile,
} from '../controllers/fileController';
import authMiddleware from '../middlewares/authMiddleware';
import upload from '../config/multer';

const router = Router();

// Upload a new file (multer handles the file in `req.file`)
router.post('/upload', authMiddleware, upload.single('file'), uploadFile);

// Get all files for the authenticated user
router.get('/', authMiddleware, getFiles);

// Get a specific file by ID
router.get('/:id', authMiddleware, getFileById);

// Update a file (e.g., change metadata)
router.put('/:id', authMiddleware, updateFile);

// Delete a file
router.delete('/:id', authMiddleware, deleteFile);

export default router;
