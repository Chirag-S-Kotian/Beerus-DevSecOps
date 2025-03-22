import express from 'express';
import dotenv from 'dotenv';
import userRoutes from './routes/userRoutes';
import fileRoutes from './routes/fileRoutes';
import cors from 'cors';

dotenv.config();


const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(express.json({ limit : '10mb'}));
app.use(express.urlencoded({ limit: '10mb', extended:true }));

// Health check endpoint for Kubernetes
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Routes
app.use('/api/users', userRoutes);
app.use('/api/files', fileRoutes);

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});