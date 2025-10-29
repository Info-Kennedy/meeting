import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chime/common/bloc/network_bloc.dart';

class NetworkBanner extends StatefulWidget {
  const NetworkBanner({super.key});

  @override
  State<NetworkBanner> createState() => _NetworkBannerState();
}

class _NetworkBannerState extends State<NetworkBanner> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    // Initialize network monitoring
    context.read<NetworkBloc>().add(const InitializeNetwork());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NetworkBloc, NetworkState>(
      listener: (context, state) {
        if (state.showBanner) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      },
      builder: (context, state) {
        if (!state.showBanner) {
          return const SizedBox.shrink();
        }

        return Material(
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 50 * _slideAnimation.value),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: state.isConnected ? Colors.green : Colors.red),
                  child: Row(
                    children: [
                      Icon(state.isConnected ? Icons.wifi : Icons.wifi_off, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.isConnected ? 'Network connected' : 'No internet connection',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.read<NetworkBloc>().add(const HideNetworkBanner());
                        },
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
