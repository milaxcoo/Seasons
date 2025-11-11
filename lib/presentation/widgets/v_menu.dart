import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seasons/data/models/voting_event.dart' as model;
import 'package:seasons/presentation/widgets/custom_icons.dart';

class VMenu extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onPanelSelected;
  final Map<model.VotingStatus, int> hasEvents;

  const VMenu({
    Key? key,
    required this.selectedIndex,
    required this.onPanelSelected,
    required this.hasEvents,
  }) : super(key: key);

  @override
  _VMenuState createState() => _VMenuState();
}

class _VMenuState extends State<VMenu> {
  double _left = 0.0;
  final GlobalKey _menuKey = GlobalKey();
  final List<GlobalKey> _itemKeys = [GlobalKey(), GlobalKey(), GlobalKey()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateBorderPosition());
  }

  void _updateBorderPosition() {
    if (_itemKeys[widget.selectedIndex].currentContext == null ||
        _menuKey.currentContext == null) {
      return;
    }

    final RenderBox activeItem =
        _itemKeys[widget.selectedIndex].currentContext!.findRenderObject() as RenderBox;
    final RenderBox menu =
        _menuKey.currentContext!.findRenderObject() as RenderBox;

    final activeItemOffset = activeItem.localToGlobal(Offset.zero, ancestor: menu);

    setState(() {
      _left = activeItemOffset.dx - (120 - activeItem.size.width) / 2;
    });
  }

  @override
  void didUpdateWidget(VMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateBorderPosition());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _menuKey,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  left: _left,
                  bottom: -10,
                  width: 120,
                  height: 50,
                  child: SvgPicture.asset(
                    'assets/svgs/brow.svg',
                    colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.5), BlendMode.srcIn),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _VMenuItem(
                      key: _itemKeys[0],
                      icon: RegistrationIcon(isSelected: widget.selectedIndex == 0),
                      isSelected: widget.selectedIndex == 0,
                      onTap: () => widget.onPanelSelected(0),
                      hasActiveEvents: widget.hasEvents[model.VotingStatus.registration]! > 0,
                    ),
                    _VMenuItem(
                      key: _itemKeys[1],
                      icon: ActiveVotingIcon(isSelected: widget.selectedIndex == 1),
                      isSelected: widget.selectedIndex == 1,
                      onTap: () => widget.onPanelSelected(1),
                      hasActiveEvents: widget.hasEvents[model.VotingStatus.active]! > 0,
                    ),
                    _VMenuItem(
                      key: _itemKeys[2],
                      icon: ResultsIcon(isSelected: widget.selectedIndex == 2),
                      isSelected: widget.selectedIndex == 2,
                      onTap: () => widget.onPanelSelected(2),
                      hasActiveEvents: widget.hasEvents[model.VotingStatus.completed]! > 0,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VMenuItem extends StatefulWidget {
  final Widget icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasActiveEvents;

  const _VMenuItem({
    Key? key,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.hasActiveEvents,
  }) : super(key: key);

  @override
  _VMenuItemState createState() => _VMenuItemState();
}

class _VMenuItemState extends State<_VMenuItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _translateAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.4 * 16))
            .animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _VMenuItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: _translateAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isSelected
                  ? Colors.white.withOpacity(0.9)
                  : widget.hasActiveEvents
                      ? const Color(0xFF00A94F)
                      : const Color(0xFF6d9fc5),
            ),
            child: widget.icon,
          ),
        ),
      ),
    );
  }
}
