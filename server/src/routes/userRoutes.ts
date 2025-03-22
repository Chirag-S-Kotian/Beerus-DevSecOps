import { Router } from 'express';
import { registerUser, loginUser, verifyOTP } from '../controllers/userController';

const router = Router();

router.post('/register', registerUser);
router.post('/login', loginUser);
router.post('/verify', verifyOTP);

export default router;
