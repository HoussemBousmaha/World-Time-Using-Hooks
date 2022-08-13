import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends HookWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final timeZonesFuture = useMemoized(() async {
      final timeZoneUrl = Uri.parse("http://worldtimeapi.org/api/timezone");
      final timeZoneResponse = await http.get(timeZoneUrl);
      await Future.delayed(const Duration(milliseconds: 500));
      return jsonDecode(timeZoneResponse.body);
    });

    final timeZonesSnapshot = useFuture(timeZonesFuture, initialData: null);

    final isTimeZonesLoadingNotifier = useState<bool>(true);
    final isWorldTimeLoadingNotifier = useState<bool>(false);

    final selectedWorldTimeNotifier = useState({});

    final timeZonesNotifier = useState<List<dynamic>>([]);

    useEffect(() {
      if (timeZonesSnapshot.data == null) return;
      isTimeZonesLoadingNotifier.value = false;
      timeZonesNotifier.value = timeZonesSnapshot.data;
      return null;
    }, [timeZonesSnapshot.data]);

    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/day.png', fit: BoxFit.cover),
            SizedBox(
              height: double.infinity,
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.07),
                  Container(
                    width: double.infinity,
                    height: size.height * 0.73,
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    child: isTimeZonesLoadingNotifier.value
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 50),
                            physics: const ClampingScrollPhysics(),
                            itemCount: timeZonesNotifier.value.length,
                            separatorBuilder: (context, index) {
                              return const SizedBox(height: 20);
                            },
                            itemBuilder: (context, index) {
                              return TextButton(
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                                  backgroundColor: Colors.blue.shade800.withOpacity(0.75),
                                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                                  primary: Colors.white,
                                ),
                                onPressed: () async {
                                  isWorldTimeLoadingNotifier.value = true;

                                  final worldTimeUrl = Uri.parse("http://worldtimeapi.org/api/timezone/${timeZonesNotifier.value[index]}");
                                  final worldTimeResponse = await http.get(worldTimeUrl);

                                  selectedWorldTimeNotifier.value = jsonDecode(worldTimeResponse.body);

                                  await Future.delayed(const Duration(milliseconds: 500));

                                  isWorldTimeLoadingNotifier.value = false;
                                },
                                child: Text(
                                  timeZonesNotifier.value[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  SizedBox(height: size.height * 0.05),
                  Container(
                    alignment: Alignment.center,
                    height: size.height * 0.1,
                    width: size.width * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                    child: isWorldTimeLoadingNotifier.value
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selectedWorldTimeNotifier.value['timezone'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                selectedWorldTimeNotifier.value['datetime']?.substring(11, 19) ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
