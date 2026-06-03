import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plan_task.dart';
import '../state/app_state.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = DateTime.now();
    final tasks = state.tasks;
    final done = state.todayDoneCount(today);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTask(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          const Text('日常规划',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('今日完成 $done / ${tasks.length} 项',
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text('点击右下角 + 添加提醒/计划',
                      style: TextStyle(color: Colors.black45)),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (int i = 0; i < tasks.length; i++) ...[
                    _TaskTile(task: tasks[i], day: today),
                    if (i != tasks.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ]
                ],
              ),
            ),
          const SizedBox(height: 20),
          _TipsCard(),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.day});
  final PlanTask task;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final isDone = task.isDoneOn(day);
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => state.deleteTask(task.id),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: GestureDetector(
          onTap: () => state.toggleTaskDone(task.id, day),
          child: Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? task.type.color : Colors.black26,
            size: 26,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.black38 : Colors.black87,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(task.type.icon, size: 14, color: task.type.color),
            const SizedBox(width: 4),
            Text('${task.type.label} · ${task.timeLabel}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Switch(
          value: task.enabled,
          onChanged: (v) => state.updateTask(task.copyWith(enabled: v)),
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const tips = [
      '每日食盐摄入控制在 5g 以内，少吃腌制食品。',
      '坚持有氧运动，每周累计 150 分钟中等强度活动。',
      '遵医嘱按时服药，不可自行停药或减量。',
      '保证充足睡眠，戒烟限酒，保持情绪平稳。',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.tips_and_updates_outlined,
                    color: Color(0xFF2E9E6B)),
                SizedBox(width: 8),
                Text('健康小贴士',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('· ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                          child: Text(t,
                              style: const TextStyle(
                                  fontSize: 13, height: 1.4))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

Future<void> _showAddTask(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _AddTaskSheet(),
  );
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _title = TextEditingController();
  TaskType _type = TaskType.medication;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入计划名称')),
      );
      return;
    }
    final task = PlanTask(
      id: '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}',
      title: title,
      type: _type,
      hour: _time.hour,
      minute: _time.minute,
    );
    context.read<AppState>().addTask(task);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('新增计划/提醒',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: '计划名称',
                filled: true,
                fillColor: const Color(0xFFF1F3F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('类型',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskType.values.map((t) {
                final selected = t == _type;
                return ChoiceChip(
                  avatar: Icon(t.icon,
                      size: 18,
                      color: selected ? Colors.white : t.color),
                  label: Text(t.label),
                  selected: selected,
                  selectedColor: t.color,
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87),
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: () async {
                final t = await showTimePicker(
                    context: context, initialTime: _time);
                if (t != null) setState(() => _time = t);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm, size: 20),
                    const SizedBox(width: 10),
                    Text('提醒时间  ${_time.format(context)}'),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.black38),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('添加', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
