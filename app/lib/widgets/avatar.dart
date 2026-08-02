import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class Avatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final bool online;

  const Avatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.radius = 24,
    this.online = false,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl == null || imageUrl!.isEmpty) ? null : imageUrl;
    final widget = url == null
        ? CircleAvatar(
            radius: radius,
            backgroundColor: MessengerTheme.primary.withValues(alpha: 0.15),
            child: Text(
              _initials(name),
              style: TextStyle(
                color: MessengerTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: radius * 0.9,
              ),
            ),
          )
        : CircleAvatar(
            radius: radius,
            backgroundColor: MessengerTheme.inputBg,
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: url,
                placeholder: (_, __) => Container(
                  color: MessengerTheme.inputBg,
                  width: radius * 2,
                  height: radius * 2,
                ),
                errorWidget: (_, __, ___) => Container(
                  color: MessengerTheme.primary.withValues(alpha: 0.15),
                  width: radius * 2,
                  height: radius * 2,
                  child: Center(
                    child: Text(
                      _initials(name),
                      style: TextStyle(color: MessengerTheme.primary, fontSize: radius * 0.9),
                    ),
                  ),
                ),
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
              ),
            ),
          );

    if (!online) return widget;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: radius * 0.6,
            height: radius * 0.6,
            decoration: BoxDecoration(
              color: MessengerTheme.online,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
