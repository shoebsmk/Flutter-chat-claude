import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Utility class for centralized icon management.
/// 
/// Maps Material Icons to Lucide Icons for consistency across the app.
/// This allows easy updates and maintains icon consistency.
class IconMapper {
  IconMapper._();

  // Navigation icons
  static IconData get chat => LucideIcons.messageCircle;
  static IconData get aiAssistant => LucideIcons.sparkles;
  
  // Action icons
  static IconData get send => LucideIcons.send;
  static IconData get search => LucideIcons.search;
  static IconData get clear => LucideIcons.x;
  static IconData get attach => LucideIcons.paperclip;
  static IconData get delete => LucideIcons.trash2;
  static IconData get edit => LucideIcons.pencil;
  static IconData get cancel => LucideIcons.x;
  
  // User & Profile icons
  static IconData get user => LucideIcons.userCircle;
  static IconData get settings => LucideIcons.cog;
  static IconData get logout => LucideIcons.power;
  
  // Status icons
  static IconData get error => LucideIcons.alertCircle;
  static IconData get success => LucideIcons.checkCircle2;
  static IconData get read => LucideIcons.checkCheck;
  
  // Auth icons
  static IconData get email => LucideIcons.mail;
  static IconData get lock => LucideIcons.lock;
  static IconData get eye => LucideIcons.eye;
  static IconData get eyeOff => LucideIcons.eyeOff;
  
  // Media icons
  static IconData get camera => LucideIcons.camera;
  static IconData get image => LucideIcons.image;
  
  // UI icons
  static IconData get arrowBack => LucideIcons.arrowLeft;
  static IconData get moreVertical => LucideIcons.moreVertical;
  static IconData get messageSquare => LucideIcons.messageSquare;
  static IconData get searchX => LucideIcons.searchX;
  static IconData get lightbulb => LucideIcons.lightbulb;
  static IconData get fileText => LucideIcons.fileText;
}

