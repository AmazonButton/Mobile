import '../../../widgets/sample_a.dart';
import 'package:flutter/material.dart';

/// A compact explanation of the physical button, shared by both home hints.
class HomeButtonHint extends StatelessWidget {
  final String title;
  final String? subtitle;
  const HomeButtonHint({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: const LinearGradient(
        colors: [Color(0xFFECF5FF), Color(0xFFDDEEFF)],
      ),
    ),
    child: Row(
      children: [
        ExcludeSemantics(
          child: SizedBox(
            width: 55,
            height: 42,
            child: Stack(
              children: [
                Positioned(
                  left: 4,
                  bottom: 1,
                  child: Container(
                    width: 38,
                    height: 29,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Color(0xFFB8C5D3)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x220F172A),
                          blurRadius: 4,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 35,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 23,
                        height: 13,
                        decoration: BoxDecoration(
                          color: SampleA.pale,
                          border: Border.all(color: SampleA.primary),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(Icons.rss_feed, size: 19, color: SampleA.primary),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 1,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: const Color(0xFF9DC3FA),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172554),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
