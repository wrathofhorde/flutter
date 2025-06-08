# hello

Flutter 프로젝트 의존성 재설정 (가장 흔한 해결책)

Git을 통해 프로젝트를 가져왔을 때, pub get을 통해 필요한 패키지들을 다운로드하지 않아서 발생하는 경우가 대부분입니다.

프로젝트 클린:
프로젝트 폴더로 이동하여 빌드 아티팩트와 캐시를 제거합니다.

Bash

cd /path/to/your/flutter_project # 실제 프로젝트 경로로 변경
flutter clean
의존성 다시 가져오기:
pubspec.yaml 파일에 명시된 모든 의존성 패키지를 다시 다운로드합니다.

Bash

flutter pub get
이 명령어가 material.dart와 같은 핵심 패키지들을 포함하여 필요한 모든 Dart 패키지를 ~/.pub-cache 폴더에 다운로드하고 프로젝트에 연결합니다.

IDE(VS Code/Android Studio) 재시작:
flutter pub get 명령어가 성공적으로 완료되었다면, 사용하고 있는 IDE (VS Code 또는 Android Studio)를 완전히 닫았다가 다시 엽니다. 이렇게 하면 IDE가 새로 다운로드된 패키지들을 인식하고 인덱싱할 수 있습니다.
