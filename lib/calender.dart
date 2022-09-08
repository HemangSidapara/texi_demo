import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:texi_demo/event.dart';
import 'package:texi_demo/notification_services.dart';

class CalenderEvents extends StatefulWidget {
  const CalenderEvents({Key? key}) : super(key: key);

  @override
  State<CalenderEvents> createState() => _CalenderEventsState();
}

class _CalenderEventsState extends State<CalenderEvents> {
  Map<DateTime, List<Event>>? selectedEvents;
  CalendarFormat format = CalendarFormat.month;
  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();
  Map<int, int> totalEventsInDay = {};
  int number = 0;
  var setEvents = GetStorage();

  TextEditingController eventController = TextEditingController();

  @override
  void initState() {
    selectedEvents = {};
    super.initState();
  }

  List<Event> getEventsfromDay(DateTime date) {
    selectedEvents = setEvents.read('setEve') ?? {};
    return selectedEvents![date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'Event Reminder',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar(
              focusedDay: selectedDay,
              firstDay: DateTime.now(),
              lastDay: DateTime.utc(2030, 3, 14),
              calendarFormat: format,
              onFormatChanged: (CalendarFormat format) {
                setState(() {
                  format = format;
                });
              },
              startingDayOfWeek: StartingDayOfWeek.sunday,
              daysOfWeekVisible: true,
              onDaySelected: (DateTime selectDay, DateTime focusDay) {
                setState(() {
                  selectedDay = selectDay;
                  focusedDay = focusDay;
                });
                print(focusedDay);
              },
              selectedDayPredicate: (DateTime date) {
                return isSameDay(selectedDay, date);
              },
              eventLoader: getEventsfromDay,
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(5.0),
                ),
                formatButtonTextStyle: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            ...getEventsfromDay(selectedDay).map(
              (Event event) => ListTile(
                title: Text(
                  event.title,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddEvent,
        tooltip: 'Add Event',
        backgroundColor: Colors.teal,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> showAddEvent() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Add Events"),
        content: TextField(
          controller: eventController,
        ),
        actions: <Widget>[
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              "Save",
            ),
            onPressed: () {
              if (eventController.text.isEmpty) {
                return;
              } else {
                setState(
                  () {
                    if (selectedEvents![selectedDay] != null) {
                      totalEventsInDay.update(int.parse("${selectedDay.year}${selectedDay.month}${selectedDay.day}"), (value) => totalEventsInDay[int.parse("${selectedDay.year}${selectedDay.month}${selectedDay.day}")]! + 1);
                      selectedEvents![selectedDay]!.add(
                        Event(title: eventController.text),
                      );
                    } else {
                      totalEventsInDay.addAll({int.parse("${selectedDay.year}${selectedDay.month}${selectedDay.day}"): 1});
                      selectedEvents![selectedDay] = [Event(title: eventController.text)];
                    }
                    setEvents.write('setEve', selectedEvents);
                    NotifyHelper().displaceNotification(int.parse("${selectedDay.year}${selectedDay.month}${selectedDay.day}${totalEventsInDay[int.parse("${selectedDay.year}${selectedDay.month}${selectedDay.day}")]}"), selectedDay, eventController.text);
                    eventController.clear();
                    Navigator.pop(context);
                  },
                );
              }
            },
          )
        ],
      ),
    );
  }
}
