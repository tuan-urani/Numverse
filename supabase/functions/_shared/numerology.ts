import { addDays, addYears, clamp, parseIsoDate, sha256Hex } from "./runtime.ts";

const MASTER_NUMBERS = new Set([11, 22, 33]);
const VOWELS = new Set(["A", "E", "I", "O", "U", "Y"]);

export interface SnapshotComputation {
  sourceHash: string;
  rawInputJson: Record<string, unknown>;
  coreNumbersJson: Record<string, unknown>;
  birthMatrixJson: Record<string, unknown>;
  matrixAspectsJson: Record<string, unknown>;
  lifeCyclesJson: Record<string, unknown>;
}

export interface LocalDateContext {
  localDate: string;
  localYear: number;
  localMonth: number;
  localDay: number;
  personalYear: number;
  personalMonth: number;
  personalDay: number;
  activePeakNumber: number | null;
  activeChallengeNumber: number | null;
  phaseKey: string;
  phaseStartDate: string | null;
  phaseEndDate: string | null;
}

export interface CompatibilityComputation {
  score: number;
  compatibilityStructure: Record<string, unknown>;
}

function normalizeName(name: string): string {
  return name
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^A-Za-z]/g, "")
    .toUpperCase();
}

function sumDigits(value: number | string): number {
  return String(value)
    .replace(/\D/g, "")
    .split("")
    .reduce((sum, digit) => sum + Number(digit), 0);
}

function reduceNumber(value: number, preserveMasters = true): number {
  let current = Math.abs(Math.trunc(value));
  while (current > 9 && !(preserveMasters && MASTER_NUMBERS.has(current))) {
    current = sumDigits(current);
  }
  return current;
}

function letterValue(char: string): number {
  return ((char.charCodeAt(0) - 65) % 9) + 1;
}

function intersectNumbers(left: number[], right: number[]): number[] {
  const rightSet = new Set(right);
  return left.filter((value) => rightSet.has(value));
}

function buildAxis(
  key: string,
  digits: number[],
  counts: Record<number, number>,
): Record<string, unknown> {
  const totalCount = digits.reduce((sum, digit) => sum + (counts[digit] ?? 0), 0);
  const level = totalCount >= 4
    ? "strong"
    : totalCount >= 2
    ? "balanced"
    : totalCount === 1
    ? "developing"
    : "missing";

  return {
    key,
    digits,
    total_count: totalCount,
    level,
  };
}

function computeCoreNumbers(
  birthDate: string,
  fullNameForReading: string,
): Record<string, unknown> {
  const normalizedName = normalizeName(fullNameForReading);
  const nameValues = normalizedName.split("").map(letterValue);
  const vowelValues = normalizedName.split("")
    .filter((char) => VOWELS.has(char))
    .map(letterValue);
  const consonantValues = normalizedName.split("")
    .filter((char) => !VOWELS.has(char))
    .map(letterValue);

  const [year, month, day] = birthDate.split("-").map(Number);
  const lifePath = reduceNumber(sumDigits(birthDate), true);
  const birthMonth = reduceNumber(month, true);
  const birthDay = reduceNumber(day, true);
  const birthYear = reduceNumber(sumDigits(year), true);
  const expression = reduceNumber(nameValues.reduce((sum, value) => sum + value, 0), true);
  const soulUrge = reduceNumber(vowelValues.reduce((sum, value) => sum + value, 0), true);
  const personality = reduceNumber(
    consonantValues.reduce((sum, value) => sum + value, 0),
    true,
  );

  return {
    life_path: { value: lifePath, title: "So chu dao" },
    expression: { value: expression, title: "So bieu dat" },
    soul_urge: { value: soulUrge, title: "So linh hon" },
    personality: { value: personality, title: "So nhan cach" },
    birth_month: { value: birthMonth, title: "Thang sinh rut gon" },
    birth_day: { value: birthDay, title: "Ngay sinh rut gon" },
    birth_year: { value: birthYear, title: "Nam sinh rut gon" },
  };
}

function computeBirthMatrix(birthDate: string): Record<string, unknown> {
  const counts: Record<number, number> = {
    1: 0,
    2: 0,
    3: 0,
    4: 0,
    5: 0,
    6: 0,
    7: 0,
    8: 0,
    9: 0,
  };

  for (const digit of birthDate.replace(/\D/g, "")) {
    const value = Number(digit);
    if (value >= 1 && value <= 9) {
      counts[value] += 1;
    }
  }

  const strongNumbers = Object.entries(counts)
    .filter(([, count]) => count >= 2)
    .map(([digit]) => Number(digit));
  const weakNumbers = Object.entries(counts)
    .filter(([, count]) => count === 1)
    .map(([digit]) => Number(digit));
  const missingNumbers = Object.entries(counts)
    .filter(([, count]) => count === 0)
    .map(([digit]) => Number(digit));

  return {
    digit_counts: counts,
    grid: [
      [counts[1], counts[4], counts[7]],
      [counts[2], counts[5], counts[8]],
      [counts[3], counts[6], counts[9]],
    ],
    strong_numbers: strongNumbers,
    weak_numbers: weakNumbers,
    missing_numbers: missingNumbers,
  };
}

function computeMatrixAspects(
  birthMatrix: Record<string, unknown>,
): Record<string, unknown> {
  const counts = birthMatrix.digit_counts as Record<number, number>;
  const axes = {
    physical: buildAxis("physical", [1, 4, 7], counts),
    emotional: buildAxis("emotional", [2, 5, 8], counts),
    intellectual: buildAxis("intellectual", [3, 6, 9], counts),
  };

  const arrowDefinitions = [
    { key: "determination", digits: [1, 5, 9] },
    { key: "sensitivity", digits: [2, 5, 8] },
    { key: "intellect", digits: [3, 6, 9] },
    { key: "practicality", digits: [1, 4, 7] },
    { key: "planning", digits: [1, 2, 3] },
    { key: "willpower", digits: [4, 5, 6] },
    { key: "intuition", digits: [3, 5, 7] },
    { key: "activity", digits: [7, 8, 9] },
  ];

  const arrows = arrowDefinitions.map((arrow) => {
    const presentCount = arrow.digits.filter((digit) => (counts[digit] ?? 0) > 0)
      .length;
    return {
      key: arrow.key,
      digits: arrow.digits,
      status: presentCount === arrow.digits.length
        ? "present"
        : presentCount === 0
        ? "missing"
        : "partial",
      present_count: presentCount,
    };
  });

  return { axes, arrows };
}

function computeLifeCycles(
  birthDate: string,
  lifePathValue: number,
): Record<string, unknown> {
  const [year, month, day] = birthDate.split("-").map(Number);
  const reducedMonth = reduceNumber(month, true);
  const reducedDay = reduceNumber(day, true);
  const reducedYear = reduceNumber(sumDigits(year), true);
  const reducedLifePath = reduceNumber(lifePathValue, false);

  const peak1 = reduceNumber(reducedMonth + reducedDay, true);
  const peak2 = reduceNumber(reducedDay + reducedYear, true);
  const peak3 = reduceNumber(peak1 + peak2, true);
  const peak4 = reduceNumber(reducedMonth + reducedYear, true);

  const challenge1 = reduceNumber(Math.abs(reducedMonth - reducedDay), false);
  const challenge2 = reduceNumber(Math.abs(reducedDay - reducedYear), false);
  const challenge3 = reduceNumber(Math.abs(challenge1 - challenge2), false);
  const challenge4 = reduceNumber(Math.abs(reducedMonth - reducedYear), false);

  const firstEndAge = 36 - reducedLifePath;
  const secondEndAge = firstEndAge + 9;
  const thirdEndAge = secondEndAge + 9;

  const peakAgeWindows = [
    { startAge: 0, endAge: firstEndAge },
    { startAge: firstEndAge + 1, endAge: secondEndAge },
    { startAge: secondEndAge + 1, endAge: thirdEndAge },
    { startAge: thirdEndAge + 1, endAge: null },
  ];

  const challenges = [challenge1, challenge2, challenge3, challenge4];
  const peaks = [peak1, peak2, peak3, peak4];

  const peakItems = peaks.map((value, index) => {
    const window = peakAgeWindows[index];
    const startDate = addYears(birthDate, window.startAge);
    const endDate = window.endAge === null
      ? null
      : addDays(addYears(birthDate, window.endAge + 1), -1);
    return {
      index: index + 1,
      value,
      start_age: window.startAge,
      end_age: window.endAge,
      start_date: startDate,
      end_date: endDate,
    };
  });

  const challengeItems = challenges.map((value, index) => {
    const window = peakAgeWindows[index];
    const startDate = addYears(birthDate, window.startAge);
    const endDate = window.endAge === null
      ? null
      : addDays(addYears(birthDate, window.endAge + 1), -1);
    return {
      index: index + 1,
      value,
      start_age: window.startAge,
      end_age: window.endAge,
      start_date: startDate,
      end_date: endDate,
    };
  });

  return {
    peaks: peakItems,
    challenges: challengeItems,
  };
}

export async function calculateSnapshot(
  profile: Record<string, unknown>,
): Promise<SnapshotComputation> {
  const fullNameForReading = String(profile.full_name_for_reading ?? "");
  const birthDate = String(profile.birth_date ?? "");

  const coreNumbersJson = computeCoreNumbers(birthDate, fullNameForReading);
  const birthMatrixJson = computeBirthMatrix(birthDate);
  const matrixAspectsJson = computeMatrixAspects(birthMatrixJson);
  const lifeCyclesJson = computeLifeCycles(
    birthDate,
    Number(
      (coreNumbersJson.life_path as Record<string, unknown>).value ?? 0,
    ),
  );

  const rawInputJson = {
    profile_id: profile.id,
    display_name: profile.display_name,
    full_name_for_reading: fullNameForReading,
    birth_date: birthDate,
    profile_kind: profile.profile_kind,
    relation_kind: profile.relation_kind,
  };

  return {
    sourceHash: await sha256Hex(JSON.stringify(rawInputJson)),
    rawInputJson,
    coreNumbersJson,
    birthMatrixJson,
    matrixAspectsJson,
    lifeCyclesJson,
  };
}

function findActiveWindow(
  items: Array<Record<string, unknown>>,
  localDate: string,
): Record<string, unknown> {
  const active = items.find((item) => {
    const startDate = String(item.start_date);
    const endDate = item.end_date ? String(item.end_date) : null;
    return startDate <= localDate && (!endDate || localDate <= endDate);
  });

  if (active) {
    return active;
  }

  return items[items.length - 1];
}

export function calculatePersonalYear(
  birthDate: string,
  targetYear: number,
): number {
  const [, month, day] = birthDate.split("-").map(Number);
  const universalYear = reduceNumber(sumDigits(targetYear), true);
  return reduceNumber(reduceNumber(month, true) + reduceNumber(day, true) + universalYear, true);
}

export function calculatePersonalMonth(
  personalYear: number,
  targetMonth: number,
): number {
  return reduceNumber(personalYear + targetMonth, true);
}

export function calculatePersonalDay(
  personalMonth: number,
  targetDay: number,
): number {
  return reduceNumber(personalMonth + targetDay, true);
}

export function calculateLocalDateContext(
  profile: Record<string, unknown>,
  snapshot: Record<string, unknown>,
  localDate: string,
): LocalDateContext {
  const [localYear, localMonth, localDay] = localDate.split("-").map(Number);
  const birthDate = String(profile.birth_date);
  const lifeCycles = snapshot.life_cycles_json as Record<string, unknown>;
  const peaks = (lifeCycles.peaks ?? []) as Array<Record<string, unknown>>;
  const challenges = (lifeCycles.challenges ?? []) as Array<Record<string, unknown>>;
  const activePeak = findActiveWindow(peaks, localDate);
  const activeChallenge = findActiveWindow(challenges, localDate);

  const phaseStartDate = [
    activePeak.start_date ? String(activePeak.start_date) : null,
    activeChallenge.start_date ? String(activeChallenge.start_date) : null,
  ].filter(Boolean).sort().at(-1) ?? null;

  const phaseEndCandidates = [
    activePeak.end_date ? String(activePeak.end_date) : null,
    activeChallenge.end_date ? String(activeChallenge.end_date) : null,
  ].filter(Boolean).sort();
  const phaseEndDate = phaseEndCandidates.length > 0 ? phaseEndCandidates[0] : null;

  const activePeakNumber = activePeak.value === undefined || activePeak.value === null
    ? null
    : Number(activePeak.value);
  const activeChallengeNumber =
    activeChallenge.value === undefined || activeChallenge.value === null
      ? null
      : Number(activeChallenge.value);
  const phaseKey = [
    `peak${activePeak.index ?? "x"}`,
    `challenge${activeChallenge.index ?? "x"}`,
    phaseStartDate ?? "open",
    phaseEndDate ?? "open",
  ].join("-");

  const personalYear = calculatePersonalYear(birthDate, localYear);
  const personalMonth = calculatePersonalMonth(personalYear, localMonth);
  const personalDay = calculatePersonalDay(personalMonth, localDay);

  return {
    localDate,
    localYear,
    localMonth,
    localDay,
    personalYear,
    personalMonth,
    personalDay,
    activePeakNumber,
    activeChallengeNumber,
    phaseKey,
    phaseStartDate,
    phaseEndDate,
  };
}

function compatibilityDelta(left: number, right: number, sameBonus: number): number {
  const rawDiff = Math.abs(left - right);
  const diff = Math.min(rawDiff, 9 - rawDiff);
  if (diff === 0) return sameBonus;
  if (diff === 1) return 6;
  if (diff === 2) return 2;
  if (diff === 3) return -3;
  return -7;
}

export function calculateCompatibility(
  primarySnapshot: Record<string, unknown>,
  targetSnapshot: Record<string, unknown>,
): CompatibilityComputation {
  const primaryCore = primarySnapshot.core_numbers_json as Record<string, Record<string, number>>;
  const targetCore = targetSnapshot.core_numbers_json as Record<string, Record<string, number>>;
  const primaryMatrix = primarySnapshot.birth_matrix_json as Record<string, unknown>;
  const targetMatrix = targetSnapshot.birth_matrix_json as Record<string, unknown>;
  const primaryLifePath = reduceNumber(Number(primaryCore.life_path?.value ?? 0), false);
  const primaryExpression = reduceNumber(Number(primaryCore.expression?.value ?? 0), false);
  const primarySoulUrge = reduceNumber(Number(primaryCore.soul_urge?.value ?? 0), false);
  const primaryPersonality = reduceNumber(Number(primaryCore.personality?.value ?? 0), false);
  const targetLifePath = reduceNumber(Number(targetCore.life_path?.value ?? 0), false);
  const targetExpression = reduceNumber(Number(targetCore.expression?.value ?? 0), false);
  const targetSoulUrge = reduceNumber(Number(targetCore.soul_urge?.value ?? 0), false);
  const targetPersonality = reduceNumber(Number(targetCore.personality?.value ?? 0), false);

  const sharedStrong = intersectNumbers(
    (primaryMatrix.strong_numbers ?? []) as number[],
    (targetMatrix.strong_numbers ?? []) as number[],
  );
  const sharedMissing = intersectNumbers(
    (primaryMatrix.missing_numbers ?? []) as number[],
    (targetMatrix.missing_numbers ?? []) as number[],
  );

  let score = 58;
  score += compatibilityDelta(primaryLifePath, targetLifePath, 12);
  score += compatibilityDelta(primaryExpression, targetExpression, 8);
  score += compatibilityDelta(primarySoulUrge, targetSoulUrge, 8);
  score += compatibilityDelta(primaryPersonality, targetPersonality, 6);
  score += sharedStrong.length * 3;
  score -= sharedMissing.length * 2;
  score = clamp(score, 0, 100);

  const compatibilityBand = score >= 80
    ? "high"
    : score >= 65
    ? "balanced"
    : score >= 50
    ? "mixed"
    : "challenging";

  return {
    score,
    compatibilityStructure: {
      compatibility_band: compatibilityBand,
      life_path_pair: [primaryLifePath, targetLifePath],
      expression_pair: [primaryExpression, targetExpression],
      soul_urge_pair: [primarySoulUrge, targetSoulUrge],
      personality_pair: [primaryPersonality, targetPersonality],
      shared_strong_numbers: sharedStrong,
      shared_missing_numbers: sharedMissing,
      signals: [
        compatibilityBand === "high"
          ? "Hai ho so co nhieu diem hoa hop nen tang truong cung nhau."
          : compatibilityBand === "balanced"
          ? "Hai ho so co nen tang tuong doi hop, can duy tri giao tiep ro rang."
          : compatibilityBand === "mixed"
          ? "Moi quan he co ca diem hut va diem va cham, can chu dong dieu chinh."
          : "Cap ho so nay de xuat nhieu bai hoc ve cach thau hieu va ton trong khac biet.",
      ],
    },
  };
}

export function calculateStreakReward(streakCount: number): number {
  return streakCount > 0 && streakCount % 7 === 0 ? 13 : 3;
}

export function calculateAgeOnDate(birthDate: string, localDate: string): number {
  const birth = parseIsoDate(birthDate);
  const current = parseIsoDate(localDate);
  let age = current.getUTCFullYear() - birth.getUTCFullYear();
  const monthDelta = current.getUTCMonth() - birth.getUTCMonth();
  const dayDelta = current.getUTCDate() - birth.getUTCDate();

  if (monthDelta < 0 || (monthDelta === 0 && dayDelta < 0)) {
    age -= 1;
  }

  return age;
}
