import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2979FF);
    const darkBlue = Color(0xFF1565C0);
    const softBlue = Color(0xFFEDF5FF);
    const textDark = Color(0xFF1E242B);
    const textMuted = Color(0xFF6C7A89);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // --- โซน Illustration งานช่าง/ซ่อมบ้านสไตล์ Minimal ---
                  SizedBox(
                    width: 220,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. พื้นหลังทรงโค้งมนอิสระ (Blob/Backdrop) สีฟ้าพาสเทล
                        Container(
                          width: 190,
                          height: 170,
                          decoration: BoxDecoration(
                            color: softBlue,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(90),
                              topRight: Radius.circular(70),
                              bottomLeft: Radius.circular(80),
                              bottomRight: Radius.circular(100),
                            ),
                          ),
                        ),

                        // 2. แผ่นใบเช็กลิสต์/รายงานตรวจบ้าน (Clipboard Card)
                        Positioned(
                          top: 18,
                          child: Container(
                            width: 130,
                            height: 155,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withValues(alpha: 0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color: primaryBlue.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ตัวหนีบคลิปบอร์ดด้านบน
                                Center(
                                  child: Container(
                                    width: 32,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: primaryBlue.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // ไอคอนบ้านด้านบน
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: softBlue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.home_rounded,
                                        size: 18,
                                        color: primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: primaryBlue.withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // เส้นรายการงานซ่อม (Checklist items)
                                _buildChecklistRow(primaryBlue),
                                const SizedBox(height: 8),
                                _buildChecklistRow(primaryBlue),
                                const SizedBox(height: 8),
                                _buildChecklistRow(primaryBlue),
                              ],
                            ),
                          ),
                        ),

                        // 3. ป้าย Badge เครื่องมือช่าง (ประแจ & ไขควง) ลอยด้านขวาล่าง
                        Positioned(
                          right: 18,
                          bottom: 12,
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF388BFF), darkBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: darkBlue.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.build_rounded, // ประแจช่าง
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),

                        // 4. แถบสถานะ "Verified/ผ่านการซ่อม" ลอยด้านซ้ายล่าง
                        Positioned(
                          left: 14,
                          bottom: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF00C853), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'รับประกันงาน',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- สิ้นสุดโซน Illustration ---

                  const SizedBox(height: 36),

                  // หัวข้อใหญ่สีฟ้าสไตล์เดียวกับตัวอย่าง
                  const Text(
                    'บริการซ่อมบ้าน เริ่มต้นได้ที่นี่',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // คำบรรยายรอง
                  const Text(
                    'เข้าสู่ระบบเพื่อเริ่มค้นหาบริการที่เหมาะกับคุณ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Prompt',
                      fontSize: 14,
                      height: 1.6,
                      color: textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 44),

                  // ปุ่มเข้าสู่ระบบไล่เฉดสีฟ้า (Gradient Button)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF388BFF), Color(0xFF1E67FF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          context.pushNamed(AppRoute.loginEmail);
                        },
                        child: const Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ปุ่มข้อความสมัครสมาชิกด้านล่าง
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'ยังไม่มีบัญชีใช่ไหม? ',
                      style: const TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 14,
                        color: textMuted,
                      ),
                      children: [
                        TextSpan(
                          text: 'สมัครสมาชิก',
                          style: const TextStyle(
                            fontFamily: 'Prompt',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              context.pushNamed(AppRoute.registerEmail);
                            },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // เส้นจำลองรายการเช็กลิสต์ในคลิปบอร์ด
  static Widget _buildChecklistRow(Color accentColor) {
    return Row(
      children: [
        Icon(Icons.check_box_rounded, size: 14, color: accentColor.withValues(alpha: 0.8)),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE4ECF5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }
}