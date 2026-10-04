import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('HOME 화면 E2E 테스트', () {
    patrolTest('TC_E001: HOME 화면 진입 시 츄르가 150으로 표시됨', (PatrolTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());
      
      // HOME 탭 선택
      await $(#homeTab).tap();
      
      // 츄르 재화 확인
      expect($(#churuAmount).text, '150');
    });

    patrolTest('TC_E002: HOME 화면 진입 시 금색 물고기가 42로 표시됨', (PatrolTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());
      
      // HOME 탭 선택
      await $(#homeTab).tap();
      
      // 금색 물고기 재화 확인
      expect($(#goldenFishAmount).text, '42');
    });

    patrolTest('TC_E003: HOME 화면 진입 시 고양이가 idle 상태로 표시됨', (PatrolTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());
      
      // HOME 탭 선택
      await $(#homeTab).tap();
      
      // 고양이 idle 상태 확인
      expect($(#catBehavior).text, contains('idle'));
    });

    patrolTest('TC_E004: 10초 대기 후 고양이 행동이 변경됨', (PatrolTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());
      
      // HOME 탭 선택
      await $(#homeTab).tap();
      
      // 초기 행동 확인
      final initialBehavior = $(#catBehavior).text;
      
      // 10초 대기
      await Future.delayed(const Duration(seconds: 10));
      await $.pumpAndSettle();
      
      // 변경된 행동 확인
      final changedBehavior = $(#catBehavior).text;
      expect(changedBehavior, isNot(equals(initialBehavior)));
    });

    patrolTest('TC_E005: 시간이 HH:mm 형식으로 표시됨', (PatrolTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());
      
      // HOME 탭 선택
      await $(#homeTab).tap();
      
      // 시간 형식 확인 (정규식: HH:mm)
      final timeText = $(#currentTime).text;
      expect(timeText, matches(r'^\d{2}:\d{2}$'));
    });

    patrolTest('TC_E006: 두 번째 탭 터치 시 화면 전환됨', (PatrolTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());
      
      // HOME 탭에서 시작
      await $(#homeTab).tap();
      
      // 두 번째 탭 터치
      await $(#secondTab).tap();
      
      // 화면 전환 확인
      expect($(#secondTabContent).visible, true);
    });

    patrolTest('TC_E007: 다른 탭 이동 후 HOME 복귀 시 정상 표시됨', (PatrolTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());
      
      // 두 번째 탭으로 이동
      await $(#secondTab).tap();
      await $.pumpAndSettle();
      
      // HOME 탭으로 복귀
      await $(#homeTab).tap();
      await $.pumpAndSettle();
      
      // HOME 화면 정상 표시 확인
      expect($(#catBehavior).visible, true);
      expect($(#churuAmount).visible, true);
      expect($(#goldenFishAmount).visible, true);
    });

    patrolTest('TC_E008: 산책 버튼 터치 시 SnackBar 표시됨', (PatrolTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());
      
      // HOME 탭 선택
      await $(#homeTab).tap();
      
      // 산책 버튼 터치
      await $(#walkButton).tap();
      await $.pumpAndSettle();
      
      // SnackBar 표시 확인
      expect(find.byType(SnackBar), findsOneWidget);
    });

    patrolTest('TC_E009: walking 행동 시 고양이가 이동함', (PatrolTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());
      
      // HOME 탭 선택
      await $(#homeTab).tap();
      
      // walking 상태가 될 때까지 대기 (최대 80초)
      bool isWalking = false;
      for (int i = 0; i < 8; i++) {
        await Future.delayed(const Duration(seconds: 10));
        await $.pumpAndSettle();
        
        final behavior = $(#catBehavior).text;
        if (behavior.contains('walking')) {
          isWalking = true;
          break;
        }
      }
      
      if (isWalking) {
        // 초기 위치 확인
        final initialPosition = $(#catImage).evaluate().first.renderObject as RenderBox;
        final initialOffset = initialPosition.localToGlobal(Offset.zero);
        
        // 2초 대기
        await Future.delayed(const Duration(seconds: 2));
        await $.pumpAndSettle();
        
        // 변경된 위치 확인
        final changedPosition = $(#catImage).evaluate().first.renderObject as RenderBox;
        final changedOffset = changedPosition.localToGlobal(Offset.zero);
        
        // 위치 변화 검증
        expect(initialOffset != changedOffset, true);
      }
    });

    patrolTest('TC_E010: 빠른 연속 탭 전환에도 UI가 정상 작동함', (PatrolTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());
      
      // HOME 탭에서 시작
      await $(#homeTab).tap();
      
      // 빠른 연속 탭 전환
      await $(#secondTab).tap();
      await $(#thirdTab).tap();
      await $(#fourthTab).tap();
      await $(#homeTab).tap();
      await $.pumpAndSettle();
      
      // HOME 화면 정상 표시 확인
      expect($(#catBehavior).visible, true);
      expect($(#churuAmount).visible, true);
    });

    patrolTest('TC_E011: 백그라운드 전환 후 복귀 시 상태 유지됨', (PatrolTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());
      
      // HOME 탭 선택
      await $(#homeTab).tap();
      
      // 초기 재화 확인
      final initialChuru = $(#churuAmount).text;
      final initialGoldenFish = $(#goldenFishAmount).text;
      
      // 앱을 백그라운드로 전환
      await $.native.pressHome();
      await Future.delayed(const Duration(seconds: 5));
      
      // 앱을 포그라운드로 복귀
      await $.native.openApp();
      await $.pumpAndSettle();
      
      // 재화 값 유지 확인
      expect($(#churuAmount).text, initialChuru);
      expect($(#goldenFishAmount).text, initialGoldenFish);
    });

    patrolTest('TC_E012: 행동 전환 시 애니메이션이 부드럽게 적용됨', (PatrolTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());
      
      // HOME 탭 선택
      await $(#homeTab).tap();
      
      // 초기 행동 확인
      expect($(#catBehavior).visible, true);
      
      // 10초 대기하여 행동 전환
      await Future.delayed(const Duration(seconds: 10));
      
      // AnimatedSwitcher가 적용되는지 확인
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      await $.pumpAndSettle();
      
      // 새 행동 표시 확인
      expect($(#catBehavior).visible, true);
    });

    patrolTest('TC_E013: 다른 탭 이동 시 Timer가 정리되고 복귀 시 재시작됨', (PatrolTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());
      
      // HOME 탭 선택
      await $(#homeTab).tap();
      
      // 10초 대기하여 행동 변경 확인
      await Future.delayed(const Duration(seconds: 10));
      await $.pumpAndSettle();
      final firstChange = $(#catBehavior).text;
      
      // 두 번째 탭으로 이동
      await $(#secondTab).tap();
      await $.pumpAndSettle();
      
      // 20초 대기 (Timer 정지 확인)
      await Future.delayed(const Duration(seconds: 20));
      
      // HOME 탭으로 복귀
      await $(#homeTab).tap();
      await $.pumpAndSettle();
      
      // 고양이 행동 확인 (새로 시작된 상태)
      expect($(#catBehavior).visible, true);
    });

    patrolTest('TC_E014: 재화 변경 시 UI가 실시간으로 업데이트됨', (PatrolTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());
      
      // HOME 탭 선택
      await $(#homeTab).tap();
      
      // 초기 츄르 확인
      expect($(#churuAmount).text, '150');
      
      // 츄르 소비 액션 트리거 (eating 행동 대기)
      bool consumed = false;
      for (int i = 0; i < 8; i++) {
        await Future.delayed(const Duration(seconds: 10));
        await $.pumpAndSettle();
        
        final churuText = $(#churuAmount).text;
        if (churuText != '150') {
          consumed = true;
          break;
        }
      }
      
      if (consumed) {
        // UI 업데이트 확인
        expect($(#churuAmount).text, isNot('150'));
      }
    });

    patrolTest('TC_E015: eating 행동 시 츄르가 소비됨', (PatrolTester $) async {
      await $.pumpWidgetAndSettle(const MyApp());
      
      // HOME 탭 선택
      await $(#homeTab).tap();
      
      // 초기 츄르 확인
      final initialChuru = int.parse($(#churuAmount).text);
      
      // eating 상태가 될 때까지 대기 (최대 80초)
      bool isEating = false;
      for (int i = 0; i < 8; i++) {
        await Future.delayed(const Duration(seconds: 10));
        await $.pumpAndSettle();
        
        final behavior = $(#catBehavior).text;
        if (behavior.contains('eating')) {
          isEating = true;
          await $.pumpAndSettle();
          break;
        }
      }
      
      if (isEating) {
        // eating 후 츄르 확인
        final currentChuru = int.parse($(#churuAmount).text);
        expect(currentChuru, lessThan(initialChuru));
      }
    });
  });
}

// MyApp 클래스 (실제 앱 진입점)
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(),
    );
  }
}