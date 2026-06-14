import 'package:flutter/material.dart';

class AdminUtils {
  static Future<bool> checkMasterPassword(BuildContext context) async {
    String enteredPassword = "";
    const String masterPassword = "  ";
    // Iyi variable niyo igena niba password igaragara cyangwa ihishwe
    bool isObscured = true; 

    bool? isAuthorized = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // StatefulBuilder ifasha guhindura amashusho ari muri Dialog
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.amber),
                  SizedBox(width: 10),
                  Text(
                    "Master Access",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Andika ijambo ry'ibanga rya Master Admin kugira ngo ufungure iyi screen.",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    obscureText: isObscured, // Ibihishwe cyangwa ibigaragara
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.amber,
                    decoration: InputDecoration(
                      hintText: "Enter Master Password",
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                      filled: true,
                      fillColor: Colors.black26,
                      // 🔥 KAKAMENYETSO K'IJISHO (TOGGLE VISIBILITY)
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscured ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () {
                          // Iyo ukanzeho, bihindura isObscured
                          setState(() {
                            isObscured = !isObscured;
                          });
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.amber),
                      ),
                    ),
                    onChanged: (value) => enteredPassword = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("REKA", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (enteredPassword == masterPassword) {
                      Navigator.pop(context, true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Password si yo! Gerageza hanyuma."),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: const Text("EMERA", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    return isAuthorized ?? false;
  }
}