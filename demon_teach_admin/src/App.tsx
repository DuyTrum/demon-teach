import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import './App.css';

import Login from './components/Auth/Login';
import PrivateRoute from './components/Auth/PrivateRoute';
import Layout from './components/Layout/Layout';
import LessonList from './components/Lessons/LessonList';
import LessonForm from './components/Lessons/LessonForm';
import LessonDetail from './components/Lessons/LessonDetail';
import AiGenerator from './components/Generator/AiGenerator';

function App() {
  return (
    <BrowserRouter>
      <ToastContainer
        position="top-right"
        autoClose={3000}
        hideProgressBar={false}
        newestOnTop
        closeOnClick
        rtl={false}
        pauseOnFocusLoss
        draggable
        pauseOnHover
      />
      
      <Routes>
        <Route path="/login" element={<Login />} />
        
        <Route
          path="/lessons"
          element={
            <PrivateRoute>
              <Layout>
                <LessonList />
              </Layout>
            </PrivateRoute>
          }
        />
        
        <Route
          path="/lessons/new"
          element={
            <PrivateRoute>
              <Layout>
                <LessonForm />
              </Layout>
            </PrivateRoute>
          }
        />
        
        <Route
          path="/lessons/:id"
          element={
            <PrivateRoute>
              <Layout>
                <LessonDetail />
              </Layout>
            </PrivateRoute>
          }
        />
        
        <Route
          path="/lessons/:id/edit"
          element={
            <PrivateRoute>
              <Layout>
                <LessonForm />
              </Layout>
            </PrivateRoute>
          }
        />
        
        <Route
          path="/generator"
          element={
            <PrivateRoute>
              <Layout>
                <AiGenerator />
              </Layout>
            </PrivateRoute>
          }
        />
        
        <Route path="/" element={<Navigate to="/lessons" replace />} />
        <Route path="*" element={<Navigate to="/lessons" replace />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
