import os
from werkzeug.contrib.cache import RedisCache


def get_env_variable(var_name, default=None):
    """Get the environment variable or raise exception."""
    try:
        return os.environ[var_name]
    except KeyError:
        if default is not None:
            return default
        else:
            error_msg = 'The environment variable {} was missing, abort...'\
                        .format(var_name)
            raise EnvironmentError(error_msg)


if get_env_variable('INVOCATION_TYPE') is 'COMPOSE':
    MYSQL_USER = get_env_variable('MYSQL_USER')
    MYSQL_PASS = get_env_variable('MYSQL_PASS')
    MYSQL_HOST = get_env_variable('MYSQL_HOST')
    MYSQL_PORT = get_env_variable('MYSQL_PORT')
    MYSQL_DATABASE = get_env_variable('MYSQL_DATABASE')

    # The SQLAlchemy connection string.
    SQLALCHEMY_DATABASE_URI = 'mysql://%s:%s@%s:%s/%s' % (MYSQL_USER,
                                                           MYSQL_PASS,
                                                           MYSQL_HOST,
                                                           MYSQL_PORT,
                                                           MYSQL_DATABASE)
else:
    SQLALCHEMY_DATABASE_URI = get_env_variable('DB_URL')

if not get_env_variable('INVOCATION_TYPE') is 'COMPOSE':
    REDIS_HOST = get_env_variable('REDIS_HOST')
    REDIS_PORT = get_env_variable('REDIS_PORT')
else:
    REDIS_HOST = get_env_variable('REDIS_URL').split(":")[1].replace("/","")
    REDIS_PORT = get_env_variable('REDIS_URL').split(":")[2].replace("/0","")
RESULTS_BACKEND = RedisCache(host=REDIS_HOST, port=REDIS_PORT, key_prefix='superset_results')

class CeleryConfig(object):
    BROKER_URL = 'redis://%s:%s/0' % (REDIS_HOST, REDIS_PORT)
    CELERY_IMPORTS = ('superset.sql_lab', )
    CELERY_RESULT_BACKEND = 'redis://%s:%s/1' % (REDIS_HOST, REDIS_PORT)
    CELERY_ANNOTATIONS = {'tasks.add': {'rate_limit': '10/s'}}
    CELERY_TASK_PROTOCOL = 1


CELERY_CONFIG = CeleryConfig
