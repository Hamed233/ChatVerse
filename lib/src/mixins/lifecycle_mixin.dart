import 'package:flutter/material.dart';
import '../chat_controller.dart';

mixin ChatLifecycleMixin<T extends StatefulWidget> on State<T> {
  ChatController get chatController;
  bool _isObserverAdded = false;

  @override
  void initState() {
    super.initState();
    if (!_isObserverAdded) {
      WidgetsBinding.instance.addObserver(_LifecycleObserver(this));
      _isObserverAdded = true;
    }
    chatController.updateOnlineStatus(true);
  }

  @override
  void dispose() {
    if (_isObserverAdded) {
      WidgetsBinding.instance.removeObserver(_LifecycleObserver(this));
      _isObserverAdded = false;
    }
    chatController.updateOnlineStatus(false);
    super.dispose();
  }

  void handleAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        chatController.updateOnlineStatus(false);
        break;
      case AppLifecycleState.resumed:
        chatController.updateOnlineStatus(true);
        break;
    }
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  final ChatLifecycleMixin _state;

  _LifecycleObserver(this._state);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _state.handleAppLifecycleState(state);
  }
}
