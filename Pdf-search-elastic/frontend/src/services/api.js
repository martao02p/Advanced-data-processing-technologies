import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Upload PDF
export const uploadPDF = async (file) => {
  const formData = new FormData();
  formData.append('file', file);

  const response = await axios.post(`${API_BASE_URL}/upload`, formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });

  return response.data;
};

// Search documents
export const searchDocuments = async (query, page = 1, size = 10) => {
  const response = await api.get('/search', {
    params: { q: query, page, size },
  });
  return response.data;
};

// Get all documents
export const getDocuments = async (page = 1, size = 20) => {
  const response = await api.get('/documents', {
    params: { page, size },
  });
  return response.data;
};

// Get document by ID
export const getDocument = async (id) => {
  const response = await api.get(`/doc/${id}`);
  return response.data;
};

// Download document
export const getDownloadUrl = (id) => {
  return `${API_BASE_URL}/doc/${id}/download`;
};

// Delete document
export const deleteDocument = async (id) => {
  const response = await api.delete(`/doc/${id}`);
  return response.data;
};

export default api;
