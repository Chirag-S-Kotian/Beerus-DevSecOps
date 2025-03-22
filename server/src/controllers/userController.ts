import { Request, Response } from 'express';
import prisma from '../config/prisma';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

// Ensure JWT_SECRET is properly managed
const JWT_SECRET = process.env.JWT_SECRET || 'defaultsecret123456';
dotenv.config();

// OTP generation and email sending function
async function sendOTP(email: string, code: number) {
  const transporter = nodemailer.createTransport({
    service: "gmail",
    host: "smtp.gmail.com",
    port: 587,
    secure: false,
    auth: {
      user: process.env.MAIL_USER, 
      pass: process.env.MAIL_PASSWORD,
    },
  });

  const mailOptions = {
    from: 'CDrive Verification <no-reply@cdrive.com>',
    to: email,
    subject: 'CDrive Email Verification Code',
    html: `
      <div style="font-family: Arial, sans-serif; color: #333;">
        <p>Hi there,</p>
        
        <p>Thank you for registering with <strong>CDrive</strong>! Your email verification code is: 
        <span style="font-size: 18px; font-weight: bold; color: #2E86C1;">${code}</span>.
        </p>
  
        <p>Enter this code in the app to finalize your registration.</p>
        
        <p style="color: #555;">
          If this wasn’t you, please disregard this message.
        </p>
  
        <p>Cheers,</p>
        <p><strong>CDrive Team</strong></p>
      </div>
    `
  };
  
  

  try {
    await transporter.sendMail(mailOptions);
    console.log('OTP sent successfully');
  } catch (error) {
    console.error('Error sending OTP:', error);
    throw new Error('Failed to send OTP. Please try again later.');
  }
}

// Register user function
export const registerUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      res.status(400).json({ message: 'User already exists' });
      return;
    }

    // Generate a random 6-digit OTP
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user with unverified status
    const user = await prisma.user.create({
      data: { email, password: hashedPassword, verified: false, verificationCode: otpCode },
    });

    // Send OTP email
    await sendOTP(email, parseInt(otpCode));

    res.status(201).json({ message: 'Registration successful! Verify your email using the OTP sent to your inbox.' });
  } catch (error) {
    console.error('Error registering user:', error);
    res.status(500).json({ message: 'Server error. Please try again later.' });
  }
};

// OTP verification function
export const verifyOTP = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, otpCode } = req.body;

    // Find the user by email
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      res.status(400).json({ message: 'Invalid email' });
      return;
    }

    // Check if OTP matches and user is not verified
    if (user.verificationCode !== otpCode || user.verified) {
      res.status(401).json({ message: 'Invalid OTP or email already verified' });
      return;
    }

    // Update user to verified and remove OTP
    await prisma.user.update({
      where: { email },
      data: { verified: true, verificationCode: null },
    });

    res.status(200).json({ message: 'OTP verified successfully' });
  } catch (error) {
    console.error('Error verifying OTP:', error);
    res.status(500).json({ message: 'Server error. Please try again later.' });
  }
};

// Login function
export const loginUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;

    // Find the user by email
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !user.password) {
      res.status(401).json({ message: 'Invalid credentials' });
      return;
    }

    // Check if the password matches
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      res.status(401).json({ message: 'Invalid credentials' });
      return;
    }

    // Check if user is verified
    if (!user.verified) {
      res.status(401).json({ message: 'Email verification required' });
      return;
    }

    // Generate JWT
    const token = jwt.sign({ id: user.id }, JWT_SECRET, { expiresIn: '1h' });

    res.json({ token });
  } catch (error) {
    console.error('Error logging in:', error);
    res.status(500).json({ message: 'Server error. Please try again later.' });
  }
};
