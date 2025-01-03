import 'package:flutter/material.dart';

class ChatTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color sentMessageColor;
  final Color receivedMessageColor;
  final Color sentMessageTextColor;
  final Color receivedMessageTextColor;
  final Color iconColor;
  final TextStyle messageTextStyle;
  final TextStyle timeTextStyle;
  final TextStyle userNameStyle;
  final BorderRadius messageBorderRadius;
  final EdgeInsets messagePadding;
  final double maxMessageWidth;

  const ChatTheme({
    this.primaryColor = const Color(0xFF2196F3),
    this.secondaryColor = const Color(0xFF4CAF50),
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
    this.sentMessageColor = const Color(0xFF2196F3),
    this.receivedMessageColor = const Color(0xFFE0E0E0),
    this.sentMessageTextColor = Colors.white,
    this.receivedMessageTextColor = Colors.black87,
    this.iconColor = Colors.grey,
    this.messageTextStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
    ),
    this.timeTextStyle = const TextStyle(
      fontSize: 12,
      color: Colors.grey,
    ),
    this.userNameStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.grey,
    ),
    this.messageBorderRadius = const BorderRadius.all(Radius.circular(16)),
    this.messagePadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 10,
    ),
    this.maxMessageWidth = 280,
  });

  ChatTheme copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? textColor,
    Color? sentMessageColor,
    Color? receivedMessageColor,
    Color? sentMessageTextColor,
    Color? receivedMessageTextColor,
    Color? iconColor,
    TextStyle? messageTextStyle,
    TextStyle? timeTextStyle,
    TextStyle? userNameStyle,
    BorderRadius? messageBorderRadius,
    EdgeInsets? messagePadding,
    double? maxMessageWidth,
  }) {
    return ChatTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      sentMessageColor: sentMessageColor ?? this.sentMessageColor,
      receivedMessageColor: receivedMessageColor ?? this.receivedMessageColor,
      sentMessageTextColor: sentMessageTextColor ?? this.sentMessageTextColor,
      receivedMessageTextColor:
          receivedMessageTextColor ?? this.receivedMessageTextColor,
      iconColor: iconColor ?? this.iconColor,
      messageTextStyle: messageTextStyle ?? this.messageTextStyle,
      timeTextStyle: timeTextStyle ?? this.timeTextStyle,
      userNameStyle: userNameStyle ?? this.userNameStyle,
      messageBorderRadius: messageBorderRadius ?? this.messageBorderRadius,
      messagePadding: messagePadding ?? this.messagePadding,
      maxMessageWidth: maxMessageWidth ?? this.maxMessageWidth,
    );
  }

  static ChatTheme dark() {
    return const ChatTheme(
      primaryColor: Color(0xFF2196F3),
      secondaryColor: Color(0xFF4CAF50),
      backgroundColor: Color(0xFF121212),
      textColor: Colors.white,
      sentMessageColor: Color(0xFF2196F3),
      receivedMessageColor: Color(0xFF424242),
      sentMessageTextColor: Colors.white,
      receivedMessageTextColor: Colors.white,
      iconColor: Colors.grey,
      messageTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Colors.white,
      ),
      timeTextStyle: TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),
      userNameStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }
}
