// Lokasi: lib/features/my_garden/widgets/set_alarm_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/my_plant_model.dart';

class SetAlarmSheet extends StatefulWidget {
  final MyPlant myPlant;
  final Function(TimeOfDay, Set<int>) onAlarmSet;

  const SetAlarmSheet({
    super.key,
    required this.myPlant,
    required this.onAlarmSet,
  });

  @override
  State<SetAlarmSheet> createState() => _SetAlarmSheetState();
}

class _SetAlarmSheetState extends State<SetAlarmSheet> {
  late TimeOfDay _selectedTime;
  late Set<int> _selectedDays;
  final List<String> _dayLabels = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTime =
        widget.myPlant.alarmTime ?? const TimeOfDay(hour: 8, minute: 0);
    _selectedDays = Set<int>.from(widget.myPlant.alarmDays);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2C6E49);
    const Color textColor = Color(0xFF3E3636);

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF3E0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Jadwal Siram: ${widget.myPlant.plantInfo.namaTanaman}',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          Text(
            'Waktu Alarm',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: primaryColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedTime != null) {
                setState(() => _selectedTime = pickedTime);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTime.format(context),
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Icon(Icons.edit_calendar_outlined, color: primaryColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ulangi Setiap Hari',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),

          // --- PERBAIKAN DI SINI ---
          // Bungkus Center dengan SingleChildScrollView
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Center(
              child: ToggleButtons(
                isSelected: List.generate(
                  7,
                  (index) => _selectedDays.contains(index + 1),
                ),
                onPressed: (int index) {
                  setState(() {
                    final day = index + 1;
                    if (_selectedDays.contains(day)) {
                      _selectedDays.remove(day);
                    } else {
                      _selectedDays.add(day);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white,
                color: primaryColor,
                selectedBorderColor: primaryColor,
                fillColor: primaryColor,
                children: _dayLabels
                    .map(
                      (day) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          day,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          // ------------------------
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              widget.onAlarmSet(_selectedTime, _selectedDays);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              'Simpan Jadwal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
