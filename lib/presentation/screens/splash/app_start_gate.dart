import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/repositories/version_repository.dart';
import '../../../domain/models/app_status.dart';

class AppStartGate extends StatefulWidget {
  final Widget child;
  final VersionRepository repository;

  const AppStartGate({
    super.key,
    required this.child,
    this.repository = const VersionRepository(),
  });

  @override
  State<AppStartGate> createState() => _AppStartGateState();
}

class _AppStartGateState extends State<AppStartGate> {
  late final Future<AppStatus> _future;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.checkAppStatus();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppStatus>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoading();
        }

        final status = snapshot.data ?? AppStatus.upToDate;

        if (status.type == AppStatusType.upToDate) {
          return widget.child;
        }

        // Blocking dialogs
        if (!_dialogShown) {
          _dialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showBlockingDialog(status);
          });
        }

        // Keep showing a non-blank UI behind the dialog.
        return _buildLoading();
      },
    );
  }

  Widget _buildLoading() {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fitness_center, size: 48),
              SizedBox(height: 12),
              Text(
                'MuscleLog',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBlockingDialog(AppStatus status) async {
    final isUpdate = status.type == AppStatusType.updateRequired;

    final title = isUpdate ? '업데이트 필요' : '점검 중';
    final content = isUpdate
        ? '안정적인 사용을 위해 업데이트가 필요합니다.'
        : (status.message ?? '점검 중입니다.');

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: isUpdate
                ? [
                    ElevatedButton(
                      onPressed: () async {
                        final url = status.storeUrl ?? '';
                        if (url.isEmpty) return;
                        final uri = Uri.tryParse(url);
                        if (uri == null) return;
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: const Text('업데이트'),
                    ),
                  ]
                : const [],
          ),
        );
      },
    );
  }
}

