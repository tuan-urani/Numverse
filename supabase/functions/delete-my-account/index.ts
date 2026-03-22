import {
  createClients,
  hasActiveProSubscription,
  HttpError,
  requireUser,
  serveHandler,
} from '../_shared/runtime.ts';

async function handleDeleteMyAccount(req: Request): Promise<Record<string, unknown>> {
  if (req.method !== 'POST') {
    throw new HttpError(405, 'method_not_allowed');
  }

  const { admin, userClient } = createClients(req);
  const user = await requireUser(req, userClient);

  const hasActivePlan = await hasActiveProSubscription(admin, user.id);
  if (hasActivePlan) {
    throw new HttpError(409, 'PLAN_ACTIVE');
  }

  const { error } = await admin.auth.admin.deleteUser(user.id);
  if (error) {
    throw new HttpError(500, 'account_delete_failed', error);
  }

  return {
    ok: true,
    deleted_user_id: user.id,
  };
}

Deno.serve(serveHandler(handleDeleteMyAccount));
