// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  /// Client-generated UUID v7, stable across export and restore.
  final String id;
  const SessionRow({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(id: Value(id));
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(id: serializer.fromJson<String>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<String>(id)};
  }

  SessionRow copyWith({String? id}) => SessionRow(id: id ?? this.id);
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SessionRow && other.id == this.id);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<String> id;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<SessionRow> custom({
    Expression<String>? id,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({Value<String>? id, Value<int>? rowid}) {
    return SessionsCompanion(id: id ?? this.id, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingsTable extends Readings
    with TableInfo<$ReadingsTable, ReadingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _systolicMeta = const VerificationMeta(
    'systolic',
  );
  @override
  late final GeneratedColumn<int> systolic = GeneratedColumn<int>(
    'systolic',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diastolicMeta = const VerificationMeta(
    'diastolic',
  );
  @override
  late final GeneratedColumn<int> diastolic = GeneratedColumn<int>(
    'diastolic',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pulseMeta = const VerificationMeta('pulse');
  @override
  late final GeneratedColumn<int> pulse = GeneratedColumn<int>(
    'pulse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _siteMeta = const VerificationMeta('site');
  @override
  late final GeneratedColumn<String> site = GeneratedColumn<String>(
    'site',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _postureMeta = const VerificationMeta(
    'posture',
  );
  @override
  late final GeneratedColumn<String> posture = GeneratedColumn<String>(
    'posture',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medicationTimingMeta = const VerificationMeta(
    'medicationTiming',
  );
  @override
  late final GeneratedColumn<String> medicationTiming = GeneratedColumn<String>(
    'medication_timing',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    systolic,
    diastolic,
    pulse,
    takenAt,
    notes,
    site,
    posture,
    medicationTiming,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('systolic')) {
      context.handle(
        _systolicMeta,
        systolic.isAcceptableOrUnknown(data['systolic']!, _systolicMeta),
      );
    } else if (isInserting) {
      context.missing(_systolicMeta);
    }
    if (data.containsKey('diastolic')) {
      context.handle(
        _diastolicMeta,
        diastolic.isAcceptableOrUnknown(data['diastolic']!, _diastolicMeta),
      );
    } else if (isInserting) {
      context.missing(_diastolicMeta);
    }
    if (data.containsKey('pulse')) {
      context.handle(
        _pulseMeta,
        pulse.isAcceptableOrUnknown(data['pulse']!, _pulseMeta),
      );
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('site')) {
      context.handle(
        _siteMeta,
        site.isAcceptableOrUnknown(data['site']!, _siteMeta),
      );
    }
    if (data.containsKey('posture')) {
      context.handle(
        _postureMeta,
        posture.isAcceptableOrUnknown(data['posture']!, _postureMeta),
      );
    }
    if (data.containsKey('medication_timing')) {
      context.handle(
        _medicationTimingMeta,
        medicationTiming.isAcceptableOrUnknown(
          data['medication_timing']!,
          _medicationTimingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      systolic: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}systolic'],
      )!,
      diastolic: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}diastolic'],
      )!,
      pulse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pulse'],
      ),
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      site: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site'],
      ),
      posture: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}posture'],
      ),
      medicationTiming: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_timing'],
      ),
    );
  }

  @override
  $ReadingsTable createAlias(String alias) {
    return $ReadingsTable(attachedDatabase, alias);
  }
}

class ReadingRow extends DataClass implements Insertable<ReadingRow> {
  /// Client-generated UUID v7, stable across export and restore.
  final String id;

  /// The session this reading was taken on. Deleting the session deletes it.
  final String sessionId;

  /// Systolic pressure, in mmHg.
  final int systolic;

  /// Diastolic pressure, in mmHg.
  final int diastolic;

  /// Pulse in beats per minute, absent when the monitor reported none.
  final int? pulse;

  /// When the measurement was taken, stored as UTC ISO-8601 text.
  final DateTime takenAt;

  /// The note the user attached, absent when they wrote none.
  final String? notes;

  /// Where the cuff was placed, stored as the `MeasurementSite` name; absent
  /// when the user did not record it (CLAUDE.md §4).
  final String? site;

  /// The body position, stored as the `Posture` name; absent when unrecorded.
  final String? posture;

  /// Whether the reading was before or after medication, stored as the
  /// `MedicationTiming` name; absent when unrecorded.
  final String? medicationTiming;
  const ReadingRow({
    required this.id,
    required this.sessionId,
    required this.systolic,
    required this.diastolic,
    this.pulse,
    required this.takenAt,
    this.notes,
    this.site,
    this.posture,
    this.medicationTiming,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['systolic'] = Variable<int>(systolic);
    map['diastolic'] = Variable<int>(diastolic);
    if (!nullToAbsent || pulse != null) {
      map['pulse'] = Variable<int>(pulse);
    }
    map['taken_at'] = Variable<DateTime>(takenAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || site != null) {
      map['site'] = Variable<String>(site);
    }
    if (!nullToAbsent || posture != null) {
      map['posture'] = Variable<String>(posture);
    }
    if (!nullToAbsent || medicationTiming != null) {
      map['medication_timing'] = Variable<String>(medicationTiming);
    }
    return map;
  }

  ReadingsCompanion toCompanion(bool nullToAbsent) {
    return ReadingsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      systolic: Value(systolic),
      diastolic: Value(diastolic),
      pulse: pulse == null && nullToAbsent
          ? const Value.absent()
          : Value(pulse),
      takenAt: Value(takenAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      site: site == null && nullToAbsent ? const Value.absent() : Value(site),
      posture: posture == null && nullToAbsent
          ? const Value.absent()
          : Value(posture),
      medicationTiming: medicationTiming == null && nullToAbsent
          ? const Value.absent()
          : Value(medicationTiming),
    );
  }

  factory ReadingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      systolic: serializer.fromJson<int>(json['systolic']),
      diastolic: serializer.fromJson<int>(json['diastolic']),
      pulse: serializer.fromJson<int?>(json['pulse']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      site: serializer.fromJson<String?>(json['site']),
      posture: serializer.fromJson<String?>(json['posture']),
      medicationTiming: serializer.fromJson<String?>(json['medicationTiming']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'systolic': serializer.toJson<int>(systolic),
      'diastolic': serializer.toJson<int>(diastolic),
      'pulse': serializer.toJson<int?>(pulse),
      'takenAt': serializer.toJson<DateTime>(takenAt),
      'notes': serializer.toJson<String?>(notes),
      'site': serializer.toJson<String?>(site),
      'posture': serializer.toJson<String?>(posture),
      'medicationTiming': serializer.toJson<String?>(medicationTiming),
    };
  }

  ReadingRow copyWith({
    String? id,
    String? sessionId,
    int? systolic,
    int? diastolic,
    Value<int?> pulse = const Value.absent(),
    DateTime? takenAt,
    Value<String?> notes = const Value.absent(),
    Value<String?> site = const Value.absent(),
    Value<String?> posture = const Value.absent(),
    Value<String?> medicationTiming = const Value.absent(),
  }) => ReadingRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    systolic: systolic ?? this.systolic,
    diastolic: diastolic ?? this.diastolic,
    pulse: pulse.present ? pulse.value : this.pulse,
    takenAt: takenAt ?? this.takenAt,
    notes: notes.present ? notes.value : this.notes,
    site: site.present ? site.value : this.site,
    posture: posture.present ? posture.value : this.posture,
    medicationTiming: medicationTiming.present
        ? medicationTiming.value
        : this.medicationTiming,
  );
  ReadingRow copyWithCompanion(ReadingsCompanion data) {
    return ReadingRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      systolic: data.systolic.present ? data.systolic.value : this.systolic,
      diastolic: data.diastolic.present ? data.diastolic.value : this.diastolic,
      pulse: data.pulse.present ? data.pulse.value : this.pulse,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      site: data.site.present ? data.site.value : this.site,
      posture: data.posture.present ? data.posture.value : this.posture,
      medicationTiming: data.medicationTiming.present
          ? data.medicationTiming.value
          : this.medicationTiming,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('systolic: $systolic, ')
          ..write('diastolic: $diastolic, ')
          ..write('pulse: $pulse, ')
          ..write('takenAt: $takenAt, ')
          ..write('notes: $notes, ')
          ..write('site: $site, ')
          ..write('posture: $posture, ')
          ..write('medicationTiming: $medicationTiming')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    systolic,
    diastolic,
    pulse,
    takenAt,
    notes,
    site,
    posture,
    medicationTiming,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.systolic == this.systolic &&
          other.diastolic == this.diastolic &&
          other.pulse == this.pulse &&
          other.takenAt == this.takenAt &&
          other.notes == this.notes &&
          other.site == this.site &&
          other.posture == this.posture &&
          other.medicationTiming == this.medicationTiming);
}

class ReadingsCompanion extends UpdateCompanion<ReadingRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> systolic;
  final Value<int> diastolic;
  final Value<int?> pulse;
  final Value<DateTime> takenAt;
  final Value<String?> notes;
  final Value<String?> site;
  final Value<String?> posture;
  final Value<String?> medicationTiming;
  final Value<int> rowid;
  const ReadingsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.systolic = const Value.absent(),
    this.diastolic = const Value.absent(),
    this.pulse = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.site = const Value.absent(),
    this.posture = const Value.absent(),
    this.medicationTiming = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingsCompanion.insert({
    required String id,
    required String sessionId,
    required int systolic,
    required int diastolic,
    this.pulse = const Value.absent(),
    required DateTime takenAt,
    this.notes = const Value.absent(),
    this.site = const Value.absent(),
    this.posture = const Value.absent(),
    this.medicationTiming = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       systolic = Value(systolic),
       diastolic = Value(diastolic),
       takenAt = Value(takenAt);
  static Insertable<ReadingRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? systolic,
    Expression<int>? diastolic,
    Expression<int>? pulse,
    Expression<DateTime>? takenAt,
    Expression<String>? notes,
    Expression<String>? site,
    Expression<String>? posture,
    Expression<String>? medicationTiming,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (systolic != null) 'systolic': systolic,
      if (diastolic != null) 'diastolic': diastolic,
      if (pulse != null) 'pulse': pulse,
      if (takenAt != null) 'taken_at': takenAt,
      if (notes != null) 'notes': notes,
      if (site != null) 'site': site,
      if (posture != null) 'posture': posture,
      if (medicationTiming != null) 'medication_timing': medicationTiming,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<int>? systolic,
    Value<int>? diastolic,
    Value<int?>? pulse,
    Value<DateTime>? takenAt,
    Value<String?>? notes,
    Value<String?>? site,
    Value<String?>? posture,
    Value<String?>? medicationTiming,
    Value<int>? rowid,
  }) {
    return ReadingsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      takenAt: takenAt ?? this.takenAt,
      notes: notes ?? this.notes,
      site: site ?? this.site,
      posture: posture ?? this.posture,
      medicationTiming: medicationTiming ?? this.medicationTiming,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (systolic.present) {
      map['systolic'] = Variable<int>(systolic.value);
    }
    if (diastolic.present) {
      map['diastolic'] = Variable<int>(diastolic.value);
    }
    if (pulse.present) {
      map['pulse'] = Variable<int>(pulse.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (site.present) {
      map['site'] = Variable<String>(site.value);
    }
    if (posture.present) {
      map['posture'] = Variable<String>(posture.value);
    }
    if (medicationTiming.present) {
      map['medication_timing'] = Variable<String>(medicationTiming.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('systolic: $systolic, ')
          ..write('diastolic: $diastolic, ')
          ..write('pulse: $pulse, ')
          ..write('takenAt: $takenAt, ')
          ..write('notes: $notes, ')
          ..write('site: $site, ')
          ..write('posture: $posture, ')
          ..write('medicationTiming: $medicationTiming, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _settingKeyMeta = const VerificationMeta(
    'settingKey',
  );
  @override
  late final GeneratedColumn<String> settingKey = GeneratedColumn<String>(
    'setting_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settingValueMeta = const VerificationMeta(
    'settingValue',
  );
  @override
  late final GeneratedColumn<String> settingValue = GeneratedColumn<String>(
    'setting_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [settingKey, settingValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('setting_key')) {
      context.handle(
        _settingKeyMeta,
        settingKey.isAcceptableOrUnknown(data['setting_key']!, _settingKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_settingKeyMeta);
    }
    if (data.containsKey('setting_value')) {
      context.handle(
        _settingValueMeta,
        settingValue.isAcceptableOrUnknown(
          data['setting_value']!,
          _settingValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settingValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {settingKey};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      settingKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting_key'],
      )!,
      settingValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting_value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  /// The setting's name, e.g. `disclaimerAcknowledged`.
  final String settingKey;

  /// The setting's value, encoded as text by its owning repository.
  final String settingValue;
  const AppSettingRow({required this.settingKey, required this.settingValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['setting_key'] = Variable<String>(settingKey);
    map['setting_value'] = Variable<String>(settingValue);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      settingKey: Value(settingKey),
      settingValue: Value(settingValue),
    );
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      settingKey: serializer.fromJson<String>(json['settingKey']),
      settingValue: serializer.fromJson<String>(json['settingValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'settingKey': serializer.toJson<String>(settingKey),
      'settingValue': serializer.toJson<String>(settingValue),
    };
  }

  AppSettingRow copyWith({String? settingKey, String? settingValue}) =>
      AppSettingRow(
        settingKey: settingKey ?? this.settingKey,
        settingValue: settingValue ?? this.settingValue,
      );
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      settingKey: data.settingKey.present
          ? data.settingKey.value
          : this.settingKey,
      settingValue: data.settingValue.present
          ? data.settingValue.value
          : this.settingValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('settingKey: $settingKey, ')
          ..write('settingValue: $settingValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(settingKey, settingValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.settingKey == this.settingKey &&
          other.settingValue == this.settingValue);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> settingKey;
  final Value<String> settingValue;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.settingKey = const Value.absent(),
    this.settingValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String settingKey,
    required String settingValue,
    this.rowid = const Value.absent(),
  }) : settingKey = Value(settingKey),
       settingValue = Value(settingValue);
  static Insertable<AppSettingRow> custom({
    Expression<String>? settingKey,
    Expression<String>? settingValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (settingKey != null) 'setting_key': settingKey,
      if (settingValue != null) 'setting_value': settingValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? settingKey,
    Value<String>? settingValue,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      settingKey: settingKey ?? this.settingKey,
      settingValue: settingValue ?? this.settingValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (settingKey.present) {
      map['setting_key'] = Variable<String>(settingKey.value);
    }
    if (settingValue.present) {
      map['setting_value'] = Variable<String>(settingValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('settingKey: $settingKey, ')
          ..write('settingValue: $settingValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $ReadingsTable readings = $ReadingsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    readings,
    appSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('readings', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String id,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<int> rowid,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReadingsTable, List<ReadingRow>>
  _readingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readings,
    aliasName: 'sessions__id__readings__session_id',
  );

  $$ReadingsTableProcessedTableManager get readingsRefs {
    final manager = $$ReadingsTableTableManager(
      $_db,
      $_db.readings,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_readingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> readingsRefs(
    Expression<bool> Function($$ReadingsTableFilterComposer f) f,
  ) {
    final $$ReadingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readings,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingsTableFilterComposer(
            $db: $db,
            $table: $db.readings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  Expression<T> readingsRefs<T extends Object>(
    Expression<T> Function($$ReadingsTableAnnotationComposer a) f,
  ) {
    final $$ReadingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readings,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingsTableAnnotationComposer(
            $db: $db,
            $table: $db.readings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (SessionRow, $$SessionsTableReferences),
          SessionRow,
          PrefetchHooks Function({bool readingsRefs})
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SessionsCompanion(id: id, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            Value<int> rowid = const Value.absent(),
          }) => SessionsCompanion.insert(id: id, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({readingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (readingsRefs) db.readings],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (readingsRefs)
                    await $_getPrefetchedData<
                      SessionRow,
                      $SessionsTable,
                      ReadingRow
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._readingsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SessionsTableReferences(db, table, p0).readingsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, $$SessionsTableReferences),
      SessionRow,
      PrefetchHooks Function({bool readingsRefs})
    >;
typedef $$ReadingsTableCreateCompanionBuilder = ReadingsCompanion Function({
  required String id,
  required String sessionId,
  required int systolic,
  required int diastolic,
  Value<int?> pulse,
  required DateTime takenAt,
  Value<String?> notes,
  Value<String?> site,
  Value<String?> posture,
  Value<String?> medicationTiming,
  Value<int> rowid,
});
typedef $$ReadingsTableUpdateCompanionBuilder = ReadingsCompanion Function({
  Value<String> id,
  Value<String> sessionId,
  Value<int> systolic,
  Value<int> diastolic,
  Value<int?> pulse,
  Value<DateTime> takenAt,
  Value<String?> notes,
  Value<String?> site,
  Value<String?> posture,
  Value<String?> medicationTiming,
  Value<int> rowid,
});

final class $$ReadingsTableReferences
    extends BaseReferences<_$AppDatabase, $ReadingsTable, ReadingRow> {
  $$ReadingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('readings__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get systolic => $composableBuilder(
    column: $table.systolic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diastolic => $composableBuilder(
    column: $table.diastolic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pulse => $composableBuilder(
    column: $table.pulse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get site => $composableBuilder(
    column: $table.site,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posture => $composableBuilder(
    column: $table.posture,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationTiming => $composableBuilder(
    column: $table.medicationTiming,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get systolic => $composableBuilder(
    column: $table.systolic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diastolic => $composableBuilder(
    column: $table.diastolic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pulse => $composableBuilder(
    column: $table.pulse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get site => $composableBuilder(
    column: $table.site,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posture => $composableBuilder(
    column: $table.posture,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationTiming => $composableBuilder(
    column: $table.medicationTiming,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get systolic =>
      $composableBuilder(column: $table.systolic, builder: (column) => column);

  GeneratedColumn<int> get diastolic =>
      $composableBuilder(column: $table.diastolic, builder: (column) => column);

  GeneratedColumn<int> get pulse =>
      $composableBuilder(column: $table.pulse, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get site =>
      $composableBuilder(column: $table.site, builder: (column) => column);

  GeneratedColumn<String> get posture =>
      $composableBuilder(column: $table.posture, builder: (column) => column);

  GeneratedColumn<String> get medicationTiming => $composableBuilder(
    column: $table.medicationTiming,
    builder: (column) => column,
  );

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingsTable,
          ReadingRow,
          $$ReadingsTableFilterComposer,
          $$ReadingsTableOrderingComposer,
          $$ReadingsTableAnnotationComposer,
          $$ReadingsTableCreateCompanionBuilder,
          $$ReadingsTableUpdateCompanionBuilder,
          (ReadingRow, $$ReadingsTableReferences),
          ReadingRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$ReadingsTableTableManager(_$AppDatabase db, $ReadingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> systolic = const Value.absent(),
                Value<int> diastolic = const Value.absent(),
                Value<int?> pulse = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> site = const Value.absent(),
                Value<String?> posture = const Value.absent(),
                Value<String?> medicationTiming = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingsCompanion(
                id: id,
                sessionId: sessionId,
                systolic: systolic,
                diastolic: diastolic,
                pulse: pulse,
                takenAt: takenAt,
                notes: notes,
                site: site,
                posture: posture,
                medicationTiming: medicationTiming,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required int systolic,
                required int diastolic,
                Value<int?> pulse = const Value.absent(),
                required DateTime takenAt,
                Value<String?> notes = const Value.absent(),
                Value<String?> site = const Value.absent(),
                Value<String?> posture = const Value.absent(),
                Value<String?> medicationTiming = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingsCompanion.insert(
                id: id,
                sessionId: sessionId,
                systolic: systolic,
                diastolic: diastolic,
                pulse: pulse,
                takenAt: takenAt,
                notes: notes,
                site: site,
                posture: posture,
                medicationTiming: medicationTiming,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReadingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$ReadingsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$ReadingsTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReadingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingsTable,
      ReadingRow,
      $$ReadingsTableFilterComposer,
      $$ReadingsTableOrderingComposer,
      $$ReadingsTableAnnotationComposer,
      $$ReadingsTableCreateCompanionBuilder,
      $$ReadingsTableUpdateCompanionBuilder,
      (ReadingRow, $$ReadingsTableReferences),
      ReadingRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String settingKey,
      required String settingValue,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> settingKey,
      Value<String> settingValue,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settingValue => $composableBuilder(
    column: $table.settingValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingValue => $composableBuilder(
    column: $table.settingValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settingValue => $composableBuilder(
    column: $table.settingValue,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> settingKey = const Value.absent(),
                Value<String> settingValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                settingKey: settingKey,
                settingValue: settingValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String settingKey,
                required String settingValue,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                settingKey: settingKey,
                settingValue: settingValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$ReadingsTableTableManager get readings =>
      $$ReadingsTableTableManager(_db, _db.readings);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
