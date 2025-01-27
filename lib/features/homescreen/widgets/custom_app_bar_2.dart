import 'package:flutter/material.dart';

class CustomAppBar_2 extends StatelessWidget implements PreferredSizeWidget {

  const CustomAppBar_2({
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}