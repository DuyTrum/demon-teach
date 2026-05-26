import { api } from './api';
import { ApiResponse } from '../types';

export const adminService = {
  /**
   * Fetch system dashboard statistics aggregates
   */
  async getStats(): Promise<any> {
    const response = await api.get<ApiResponse<any>>('/cms/admin/stats');
    return response.data.data;
  },

  /**
   * Fetch registered users with auth + firestore merge
   */
  async getUsers(params: { page?: number; limit?: number; search?: string }): Promise<any> {
    const response = await api.get<ApiResponse<any>>('/cms/admin/users', { params });
    return response.data.data;
  },

  /**
   * Edit a user's role (admin / user)
   */
  async updateUserRole(userId: string, role: string): Promise<any> {
    const response = await api.put<ApiResponse<any>>(`/cms/admin/users/${userId}/role`, { role });
    return response.data;
  },

  /**
   * Permanently delete a user account and their records
   */
  async deleteUser(userId: string): Promise<any> {
    const response = await api.delete<ApiResponse<any>>(`/cms/admin/users/${userId}`);
    return response.data;
  },

  /**
   * Fetch leaderboard rankings for a language
   */
  async getLeaderboard(language: string): Promise<any> {
    const response = await api.get<ApiResponse<any>>(`/cms/admin/leaderboard/${language}`);
    return response.data.data;
  },

  /**
   * Edit progress metrics (XP, streak, souls)
   */
  async updateLeaderboardProgress(
    progressId: string,
    metrics: { totalXP?: number; currentStreak?: number; souls?: number }
  ): Promise<any> {
    const response = await api.put<ApiResponse<any>>(`/cms/admin/leaderboard/${progressId}`, metrics);
    return response.data;
  },

  /**
   * Reset user's progress metrics to 0
   */
  async resetLeaderboardProgress(progressId: string): Promise<any> {
    const response = await api.delete<ApiResponse<any>>(`/cms/admin/leaderboard/${progressId}`);
    return response.data;
  },

  /**
   * Post a system-wide broadcast notification doc to Firestore
   */
  async sendNotification(title: string, body: string): Promise<any> {
    const response = await api.post<ApiResponse<any>>('/cms/admin/notifications', { title, body });
    return response.data;
  },

  /**
   * Wipe Cloud Firestore user collections
   */
  async wipeFirestore(): Promise<any> {
    const response = await api.post<ApiResponse<any>>('/cms/admin/system/wipe-firestore');
    return response.data;
  },

  /**
   * Wipe Firebase Authentication users list
   */
  async wipeAuthUsers(): Promise<any> {
    const response = await api.post<ApiResponse<any>>('/cms/admin/system/wipe-auth-users');
    return response.data;
  },

  /**
   * Trigger seed script for predefined lessons
   */
  async seedLessons(): Promise<any> {
    const response = await api.post<ApiResponse<any>>('/cms/admin/system/seed-lessons');
    return response.data;
  },

  /**
   * Download a backup containing all collections
   */
  async exportBackup(): Promise<any> {
    const response = await api.get<ApiResponse<any>>('/cms/admin/backup/export');
    return response.data.data;
  },

  /**
   * Restore collections using a uploaded JSON backup
   */
  async importBackup(backup: any): Promise<any> {
    const response = await api.post<ApiResponse<any>>('/cms/admin/backup/import', { backup });
    return response.data;
  }
};
