
import { preferences } from '@kit.ArkData';

export const PREF_NAME = 'unified_preference';
export const SCHEDULE_KEY = 'scheduleInfo';

class UnifiedPreferences {

  private preferences: preferences.Preferences | null = null;

  async init(context: Context) {
    if (!this.preferences) {
      const options: preferences.Options = { name: PREF_NAME };
      try {
        this.preferences = preferences.getPreferencesSync(context, options);
      } catch (error) {
        console.error(`getPreferencesSync ERROR: [${error.name}] ${error.message}`);
      }
    }
  }

  putSync(key: string, value: string | number | boolean) {
    try {
      this.preferences?.putSync(key, value);
    } catch (error) {
      console.error(`putSync ERROR: [${error.name}] ${error.message}`);
    }
    this.flush();    // 可选：立即持久化
  }

  getSync(key: string, defaultValue: string = ''): string {
    try {
      return this.preferences?.getSync(key, defaultValue) as string;
    } catch (error) {
      console.error(`getSync ERROR: [${error.name}] ${error.message}`);
      return '';
    }
  }

  flush() {
    this.preferences?.flush()
      .catch((error: Error) => {
        console.error(`preferences flush ERROR: [${error.name}] ${error.message}`)
      })
  }

}

export default new UnifiedPreferences();
