import { Request, Response } from 'express';
import cloudinary from '../config/cloudinary';
import prisma from '../config/prisma';
import fs from 'fs';
import path from 'path';

// Extending Request to include userId
interface AuthenticatedRequest extends Request {
  userId?: string;
}

// Upload a new file
export const uploadFile = async (req: any, res: Response): Promise<void> => {
  console.log("Upload file endpoint hit");

  try {
    const { name } = req.body;
    const file = req.file;

    if (!file) {
      res.status(400).json({ message: 'No file provided' });
      return;
    }

    // Upload to Cloudinary
    const result = await cloudinary.uploader.upload(file.path);
    fs.unlinkSync(file.path); // Remove the file from the server after uploading

    // Create new file entry in Prisma
    const newFile = await prisma.file.create({
      data: {
        name: name, 
        url: result.secure_url,
        userId: req.userId,
      },
    });

    res.status(201).json(newFile);
  } catch (error) {
    console.error("Upload file error:", error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get all files for a user
export const getFiles = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const files = await prisma.file.findMany({ where: { userId: req.userId } });
    res.status(200).json(files);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get a file by ID
export const getFileById = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const file = await prisma.file.findUnique({ where: { id: req.params.id, userId: req.userId } });

    if (!file) {
      res.status(404).json({ message: 'File not found' });
      return;
    }

    res.status(200).json(file);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Update a file
export const updateFile = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const { name } = req.body;
    const file = await prisma.file.update({
      where: { id: req.params.id, userId: req.userId },
      data: { name },
    });

    res.status(200).json(file);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Delete a file
export const deleteFile = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const file = await prisma.file.findUnique({ where: { id: req.params.id, userId: req.userId } });

    if (!file) {
      res.status(404).json({ message: 'File not found' });
      return;
    }

    const publicId = file.url.split('/').slice(-1)[0].split('.')[0];

    // Delete the file from Cloudinary using the public ID
    await cloudinary.uploader.destroy(publicId);

    // Delete the file record from the database
    await prisma.file.delete({ where: { id: file.id } });

    res.status(200).json({ message: 'File deleted successfully' });
  } catch (error) {
    console.error('Error deleting file:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

