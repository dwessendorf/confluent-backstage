import { createBackendModule } from '@backstage/backend-plugin-api';
import { scaffolderActionsExtensionPoint } from '@backstage/plugin-scaffolder-node/alpha';
import { createGetConfluentCredentialsAction } from '../plugins/scaffolder/actions';

/**
 * Module that adds the Confluent actions to the scaffolder.
 * @public
 */
export const scaffolderConfluentActionsModule = createBackendModule({
  pluginId: 'scaffolder',
  moduleId: 'confluent-actions',
  register(env) {
    env.registerInit({
      deps: {
        scaffolderActions: scaffolderActionsExtensionPoint,
      },
      async init({ scaffolderActions }) {
        scaffolderActions.addActions(
          createGetConfluentCredentialsAction() 
        );
      },
    });
  },
}); 