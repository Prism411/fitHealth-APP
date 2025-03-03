
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const FitHealthApp());
}

class FitHealthApp extends StatelessWidget {
  const FitHealthApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fit Health',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<WorkoutPlan> _workoutPlans = [];
  final List<DailyProgress> _dailyProgress = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadData();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Carregar planos de treino
    final workoutPlansJson = prefs.getStringList('workoutPlans') ?? [];
    setState(() {
      _workoutPlans.clear();
      for (var json in workoutPlansJson) {
        _workoutPlans.add(WorkoutPlan.fromJson(jsonDecode(json)));
      }
    });
    
    // Carregar progresso diário
    final progressJson = prefs.getStringList('dailyProgress') ?? [];
    setState(() {
      _dailyProgress.clear();
      for (var json in progressJson) {
        _dailyProgress.add(DailyProgress.fromJson(jsonDecode(json)));
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Salvar planos de treino
    final workoutPlansJson = _workoutPlans
        .map((plan) => jsonEncode(plan.toJson()))
        .toList();
    await prefs.setStringList('workoutPlans', workoutPlansJson);
    
    // Salvar progresso diário
    final progressJson = _dailyProgress
        .map((progress) => jsonEncode(progress.toJson()))
        .toList();
    await prefs.setStringList('dailyProgress', progressJson);
  }

  void _addWorkoutPlan(WorkoutPlan plan) {
    setState(() {
      _workoutPlans.add(plan);
    });
    _saveData();
  }

  void _updateWorkoutPlan(int index, WorkoutPlan plan) {
    setState(() {
      _workoutPlans[index] = plan;
    });
    _saveData();
  }

  void _deleteWorkoutPlan(int index) {
    setState(() {
      _workoutPlans.removeAt(index);
    });
    _saveData();
  }

  void _recordDailyProgress(DailyProgress progress) {
    setState(() {
      // Verificar se já existe progresso para o dia
      final existingIndex = _dailyProgress.indexWhere(
          (p) => p.date.year == progress.date.year && 
                p.date.month == progress.date.month && 
                p.date.day == progress.date.day);
      
      if (existingIndex >= 0) {
        _dailyProgress[existingIndex] = progress;
      } else {
        _dailyProgress.add(progress);
      }
    });
    _saveData();
  }

  void _scheduleNotification(TimeOfDay time, List<int> days) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'workout_channel',
      'Lembretes de Treino',
      channelDescription: 'Canal para lembretes de treino',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    
    // Implementação básica - na versão completa, usaria um plugin para agendamento recorrente
    await _notificationsPlugin.show(
      0,
      'Hora de treinar!',
      'Não esqueça do seu treino hoje!',
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fit Health'),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              labelColor: Colors.blue,
              tabs: [
                Tab(icon: Icon(Icons.fitness_center), text: 'Planos'),
                Tab(icon: Icon(Icons.calendar_today), text: 'Progresso'),
                Tab(icon: Icon(Icons.notifications), text: 'Lembretes'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildWorkoutPlansTab(),
                  _buildProgressTab(),
                  _buildNotificationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWorkoutPlanDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Plano de Treino',
      ),
    );
  }

  Widget _buildWorkoutPlansTab() {
    return _workoutPlans.isEmpty
        ? const Center(child: Text('Nenhum plano de treino criado ainda.'))
        : ListView.builder(
            itemCount: _workoutPlans.length,
            itemBuilder: (context, index) {
              final plan = _workoutPlans[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(plan.name),
                  subtitle: Text('${plan.exercises.length} exercícios'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditWorkoutPlanDialog(context, index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteWorkoutPlan(index),
                      ),
                    ],
                  ),
                  onTap: () => _showWorkoutPlanDetails(context, plan, index),
                ),
              );
            },
          );
  }

  Widget _buildProgressTab() {
    return _dailyProgress.isEmpty
        ? const Center(child: Text('Nenhum progresso registrado ainda.'))
        : ListView.builder(
            itemCount: _dailyProgress.length,
            itemBuilder: (context, index) {
              final progress = _dailyProgress[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('${progress.date.day}/${progress.date.month}/${progress.date.year}'),
                  subtitle: Text('${progress.completedExercises.length} exercícios concluídos'),
                  onTap: () => _showProgressDetails(context, progress),
                ),
              );
            },
          );
  }

  Widget _buildNotificationsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configurar Lembretes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showAddNotificationDialog(context),
            child: const Text('Adicionar Lembrete'),
          ),
          // Aqui seria implementada a lista de lembretes configurados
        ],
      ),
    );
  }

  void _showAddWorkoutPlanDialog(BuildContext context) {
    final nameController = TextEditingController();
    final exercises = <Exercise>[];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Novo Plano de Treino'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nome do Plano'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Exercícios:'),
                    ...exercises.asMap().entries.map((entry) {
                      final i = entry.key;
                      final exercise = entry.value;
                      return ListTile(
                        title: Text(exercise.name),
                        subtitle: Text('${exercise.repetitions} reps, ${exercise.duration} min'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              exercises.removeAt(i);
                            });
                          },
                        ),
                      );
                    }),
                    ElevatedButton(
                      onPressed: () => _showAddExerciseDialog(context, (exercise) {
                        setState(() {
                          exercises.add(exercise);
                        });
                      }),
                      child: const Text('Adicionar Exercício'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty && exercises.isNotEmpty) {
                      _addWorkoutPlan(WorkoutPlan(
                        name: nameController.text,
                        exercises: exercises,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditWorkoutPlanDialog(BuildContext context, int planIndex) {
    final plan = _workoutPlans[planIndex];
    final nameController = TextEditingController(text: plan.name);
    final exercises = List<Exercise>.from(plan.exercises);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Plano de Treino'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nome do Plano'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Exercícios:'),
                    ...exercises.asMap().entries.map((entry) {
                      final i = entry.key;
                      final exercise = entry.value;
                      return ListTile(
                        title: Text(exercise.name),
                        subtitle: Text('${exercise.repetitions} reps, ${exercise.duration} min'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              exercises.removeAt(i);
                            });
                          },
                        ),
                      );
                    }),
                    ElevatedButton(
                      onPressed: () => _showAddExerciseDialog(context, (exercise) {
                        setState(() {
                          exercises.add(exercise);
                        });
                      }),
                      child: const Text('Adicionar Exercício'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty && exercises.isNotEmpty) {
                      _updateWorkoutPlan(
                        planIndex,
                        WorkoutPlan(
                          name: nameController.text,
                          exercises: exercises,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddExerciseDialog(BuildContext context, Function(Exercise) onAdd) {
    final nameController = TextEditingController();
    final repsController = TextEditingController();
    final durationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Exercício'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome do Exercício'),
              ),
              TextField(
                controller: repsController,
                decoration: const InputDecoration(labelText: 'Repetições'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Duração (minutos)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    repsController.text.isNotEmpty &&
                    durationController.text.isNotEmpty) {
                  onAdd(Exercise(
                    name: nameController.text,
                    repetitions: int.parse(repsController.text),
                    duration: int.parse(durationController.text),
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  void _showWorkoutPlanDetails(BuildContext context, WorkoutPlan plan, int planIndex) {
    final completedExercises = <String>{};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(plan.name),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...plan.exercises.map((exercise) {
                      final isCompleted = completedExercises.contains(exercise.name);
                      return CheckboxListTile(
                        title: Text(exercise.name),
                        subtitle: Text('${exercise.repetitions} reps, ${exercise.duration} min'),
                        value: isCompleted,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              completedExercises.add(exercise.name);
                            } else {
                              completedExercises.remove(exercise.name);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
                TextButton(
                  onPressed: () {
                    final completed = plan.exercises
                        .where((e) => completedExercises.contains(e.name))
                        .toList();
                    
                    _recordDailyProgress(DailyProgress(
                      date: DateTime.now(),
                      workoutPlanId: planIndex,
                      completedExercises: completed,
                    ));
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Progresso registrado!')),
                    );
                  },
                  child: const Text('Registrar Progresso'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showProgressDetails(BuildContext context, DailyProgress progress) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Progresso - ${progress.date.day}/${progress.date.month}/${progress.date.year}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...progress.completedExercises.map((exercise) {
                  return ListTile(
                    title: Text(exercise.name),
                    subtitle: Text('${exercise.repetitions} reps, ${exercise.duration} min'),
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _showAddNotificationDialog(BuildContext context) {
    TimeOfDay selectedTime = TimeOfDay.now();
    final daysOfWeek = <int>[];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Adicionar Lembrete'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Horário'),
                    subtitle: Text('${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                    onTap: () async {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = time;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Dias da Semana:'),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      for (int i = 1; i <= 7; i++)
                        FilterChip(
                          label: Text(_getDayName(i)),
                          selected: daysOfWeek.contains(i),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                daysOfWeek.add(i);
                              } else {
                                daysOfWeek.remove(i);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (daysOfWeek.isNotEmpty) {
                      _scheduleNotification(selectedTime, daysOfWeek);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lembrete configurado!')),
                      );
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getDayName(int day) {
    switch (day) {
      case 1: return 'Seg';
      case 2: return 'Ter';
      case 3: return 'Qua';
      case 4: return 'Qui';
      case 5: return 'Sex';
      case 6: return 'Sáb';
      case 7: return 'Dom';
      default: return '';
    }
  }
}

class Exercise {
  final String name;
  final int repetitions;
  final int duration; // em minutos

  Exercise({
    required this.name,
    required this.repetitions,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'repetitions': repetitions,
      'duration': duration,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'],
      repetitions: json['repetitions'],
      duration: json['duration'],
    );
  }
}

class WorkoutPlan {
  final String name;
  final List<Exercise> exercises;

  WorkoutPlan({
    required this.name,
    required this.exercises,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      name: json['name'],
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(e))
          .toList(),
    );
  }
}

class DailyProgress {
  final DateTime date;
  final int workoutPlanId;
  final List<Exercise> completedExercises;

  DailyProgress({
    required this.date,
    required this.workoutPlanId,
    required this.completedExercises,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'workoutPlanId': workoutPlanId,
      'completedExercises': completedExercises.map((e) => e.toJson()).toList(),
    };
  }

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    return DailyProgress(
      date: DateTime.parse(json['date']),
      workoutPlanId: json['workoutPlanId'],
      completedExercises: (json['completedExercises'] as List)
          .map((e) => Exercise.fromJson(e))
          .toList(),
    );
  }
}
