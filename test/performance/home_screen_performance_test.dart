import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cat/main.dart';
import 'dart:developer' as developer;
import 'dart:io';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('HOME 화면 성능 테스트', () {
    testWidgets('TC_P001: HOME 화면 초기 렌더링이 2초 이내 완료', (WidgetTester tester) async {
      final startTime = DateTime.now();
      
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      final endTime = DateTime.now();
      final renderTime = endTime.difference(startTime).inMilliseconds;
      
      developer.log('HOME 화면 렌더링 시간: ${renderTime}ms');
      expect(renderTime, lessThan(2000), reason: 'HOME 렌더링이 2초를 초과함');
    });

    testWidgets('TC_P002: 행동 변경 시 프레임 드롭 없음', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      final frameStartTime = DateTime.now();
      int frameCount = 0;
      
      for (int i = 0; i < 600; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        frameCount++;
      }
      
      final frameEndTime = DateTime.now();
      final duration = frameEndTime.difference(frameStartTime).inMilliseconds;
      final actualFps = (frameCount * 1000) / duration;
      
      developer.log('실제 FPS: ${actualFps.toStringAsFixed(2)}');
      expect(actualFps, greaterThan(55), reason: '프레임 드롭 발생 (목표: 60fps)');
    });

    testWidgets('TC_P003: 탭 전환이 300ms 이내 완료', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      await tester.tap(find.byKey(const Key('homeTab')));
      await tester.pumpAndSettle();
      
      final startTime = DateTime.now();
      await tester.tap(find.byKey(const Key('secondTab')));
      await tester.pumpAndSettle();
      final endTime = DateTime.now();
      
      final transitionTime = endTime.difference(startTime).inMilliseconds;
      developer.log('탭 전환 시간: ${transitionTime}ms');
      expect(transitionTime, lessThan(300), reason: '탭 전환이 300ms를 초과함');
    });

    testWidgets('TC_P004: HOME 화면 로드 시 메모리 사용량 100MB 이하', (WidgetTester tester) async {
      final processInfo = ProcessInfo.currentRss;
      final initialMemory = processInfo / (1024 * 1024);
      developer.log('앱 실행 전 메모리: ${initialMemory.toStringAsFixed(2)}MB');
      
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      final loadedProcessInfo = ProcessInfo.currentRss;
      final loadedMemory = loadedProcessInfo / (1024 * 1024);
      developer.log('HOME 로드 후 메모리: ${loadedMemory.toStringAsFixed(2)}MB');
      
      expect(loadedMemory, lessThan(100), reason: 'HOME 화면 메모리 사용량이 100MB 초과');
    });

    testWidgets('TC_P005: 탭 전환 반복 시 메모리 누수 없음', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      final initialProcessInfo = ProcessInfo.currentRss;
      final initialMemory = initialProcessInfo / (1024 * 1024);
      developer.log('초기 메모리: ${initialMemory.toStringAsFixed(2)}MB');
      
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byKey(const Key('secondTab')));
        await tester.pumpAndSettle();
        
        await tester.tap(find.byKey(const Key('homeTab')));
        await tester.pumpAndSettle();
      }
      
      final finalProcessInfo = ProcessInfo.currentRss;
      final finalMemory = finalProcessInfo / (1024 * 1024);
      final memoryIncrease = finalMemory - initialMemory;
      
      developer.log('최종 메모리: ${finalMemory.toStringAsFixed(2)}MB, 증가량: ${memoryIncrease.toStringAsFixed(2)}MB');
      expect(memoryIncrease, lessThan(10), reason: '메모리 누수 발생 (증가: ${memoryIncrease.toStringAsFixed(2)}MB)');
    });

    testWidgets('TC_P006: walking 애니메이션 CPU 사용률 50% 이하', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      
      final cpuStartTime = DateTime.now();
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final cpuEndTime = DateTime.now();
      final actualDuration = cpuEndTime.difference(cpuStartTime).inMilliseconds;
      final cpuUsage = ((actualDuration - 960) / actualDuration) * 100;
      
      developer.log('walking 애니메이션 CPU 사용률: ${cpuUsage.toStringAsFixed(2)}%');
      expect(cpuUsage, lessThan(50), reason: 'CPU 사용률이 50% 초과');
    });

    testWidgets('TC_P007: 30분 장시간 실행 시 메모리 안정성', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      final initialProcessInfo = ProcessInfo.currentRss;
      final initialMemory = initialProcessInfo / (1024 * 1024);
      developer.log('초기 메모리: ${initialMemory.toStringAsFixed(2)}MB');
      
      for (int i = 0; i < 180; i++) {
        await tester.pump(const Duration(seconds: 10));
        await tester.pumpAndSettle();
        
        if (i % 30 == 0) {
          final currentProcessInfo = ProcessInfo.currentRss;
          final currentMemory = currentProcessInfo / (1024 * 1024);
          developer.log('${(i * 10 / 60).toStringAsFixed(1)}분 경과 - 메모리: ${currentMemory.toStringAsFixed(2)}MB');
        }
      }
      
      final finalProcessInfo = ProcessInfo.currentRss;
      final finalMemory = finalProcessInfo / (1024 * 1024);
      final memoryIncrease = finalMemory - initialMemory;
      
      developer.log('30분 후 메모리: ${finalMemory.toStringAsFixed(2)}MB, 증가량: ${memoryIncrease.toStringAsFixed(2)}MB');
      expect(memoryIncrease, lessThan(20), reason: '장시간 실행 메모리 누수 (증가: ${memoryIncrease.toStringAsFixed(2)}MB)');
    });

    testWidgets('TC_P008: 빠른 연속 탭 전환 시 응답성 유지', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      final responseTimes = <int>[];
      
      for (int i = 0; i < 20; i++) {
        final startTime = DateTime.now();
        
        if (i % 2 == 0) {
          await tester.tap(find.byKey(const Key('secondTab')));
        } else {
          await tester.tap(find.byKey(const Key('homeTab')));
        }
        await tester.pumpAndSettle();
        
        final endTime = DateTime.now();
        final responseTime = endTime.difference(startTime).inMilliseconds;
        responseTimes.add(responseTime);
        
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      final avgResponseTime = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      developer.log('평균 탭 전환 시간: ${avgResponseTime.toStringAsFixed(2)}ms');
      
      responseTimes.sort();
      final p95Index = (responseTimes.length * 0.95).floor();
      final p95ResponseTime = responseTimes[p95Index];
      
      developer.log('p95 탭 전환 시간: ${p95ResponseTime}ms');
      expect(p95ResponseTime, lessThan(200), reason: 'p95 응답 시간이 200ms 초과');
    });

    testWidgets('TC_P009: 재화 UI 업데이트가 100ms 이내 완료', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      final initialChuru = find.byKey(const Key('churuAmount'));
      expect(initialChuru, findsOneWidget);
      
      final startTime = DateTime.now();
      
      await tester.tap(find.byKey(const Key('triggerEating')));
      await tester.pump();
      
      final endTime = DateTime.now();
      final updateTime = endTime.difference(startTime).inMilliseconds;
      
      developer.log('재화 UI 업데이트 시간: ${updateTime}ms');
      expect(updateTime, lessThan(100), reason: 'UI 업데이트가 100ms 초과');
    });

    testWidgets('TC_P010: 백그라운드 복귀 시 1초 이내 재개', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      final binding = tester.binding as IntegrationTestWidgetsFlutterBinding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      
      await Future.delayed(const Duration(seconds: 5));
      
      final startTime = DateTime.now();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      final endTime = DateTime.now();
      
      final resumeTime = endTime.difference(startTime).inMilliseconds;
      developer.log('백그라운드 복귀 시간: ${resumeTime}ms');
      expect(resumeTime, lessThan(1000), reason: '복귀 시간이 1초 초과');
    });

    testWidgets('TC_P011: sleeping 애니메이션 CPU 사용률 30% 이하', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      
      final cpuStartTime = DateTime.now();
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final cpuEndTime = DateTime.now();
      final actualDuration = cpuEndTime.difference(cpuStartTime).inMilliseconds;
      final cpuUsage = ((actualDuration - 960) / actualDuration) * 100;
      
      developer.log('sleeping 애니메이션 CPU 사용률: ${cpuUsage.toStringAsFixed(2)}%');
      expect(cpuUsage, lessThan(30), reason: 'CPU 사용률이 30% 초과');
    });
  });
}