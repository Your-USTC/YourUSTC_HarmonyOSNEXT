import { preferences } from '@kit.ArkData';

export const PREF_NAME = 'unified_preference';
export const SCHEDULE_KEY = 'scheduleInfo';

class UnifiedPreferences {
  private preferences: preferences.Preferences | null = null;

  async init(context: Context) {
    if (!this.preferences) {
      const options: preferences.Options = { name: PREF_NAME };
      this.preferences = preferences.getPreferencesSync(context, options);
    }
  }

  putSync(key: string, value: string | number | boolean) {
    this.preferences?.putSync(key, value);
    this.flush(); // 可选：立即持久化
  }

  getSync(key: string, defaultValue: string = ''): string {
    return this.preferences?.getSync(key, defaultValue) as string;
  }

  flush() {
    this.preferences?.flush();
  }
}

export default new UnifiedPreferences();