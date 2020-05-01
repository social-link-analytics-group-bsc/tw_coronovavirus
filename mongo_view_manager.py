from datetime import datetime
from src.utils.db_manager import DBManager

import click
import os
import sys


# Add the directory to the sys.path
path_current_file = os.path.dirname(os.path.abspath(__file__))
path_src = os.path.join(path_current_file, 'src')
sys.path.append(os.path.dirname(path_src))
path_utils = os.path.join(path_src, 'utils')
sys.path.append(os.path.dirname(path_utils))


@click.group()
def run():
    pass


@run.command()
@click.argument('name') # Name of view
@click.argument('source') # Name of view source
@click.option('--start_date', help='Start date', default='', is_flag=False)
@click.option('--end_date', help='End date', default='', is_flag=False)
@click.option('--config_file', help='File with Mongo configuration', \
              default=None, is_flag=False)
def create_week_view(name, source, start_date, end_date, config_file):
    dbm = DBManager(config_fn=config_file)
    if not start_date:
        start_date = datetime.today().strftime('%Y-%m-%d')
    query = [{'$match':{'created_at_date':{'$gte':start_date}}}]
    if end_date:
        query[0]['$match']['created_at_date'].update(
            {
                '$lte': end_date
            }
        )
    dbm.create_view(name, source, query)


@run.command()
@click.argument('name') # Name of view to remove
@click.option('--config_file', help='File with Mongo configuration', \
              default=None, is_flag=False)
def remove_view(name, config_file):
    dbm = DBManager(config_fn=config_file)
    dbm.drop_collection(name)    


if __name__ == "__main__":
    run()