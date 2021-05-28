"""
Python add-on for data preprocessing and trade movement process in the metapop
"""

import csv
import dateutil.parser             as     dup
import numpy                       as     np

from   emulsion.agent.managers     import MetapopProcessManager
from   emulsion.tools.preprocessor import EmulsionPreprocessor
from   emulsion.tools.debug        import debuginfo
from   emulsion.model.exceptions   import SemanticException

#===============================================================
# Preprocessor class for restructuring the file of trade movements
#===============================================================
class TradeMovementsReader(EmulsionPreprocessor):
    """A preprocessor class for reading the CSV that describes the trade
    movements and restructuring it as a dictionary, stored in shared
    information in the simulation.

    """
    def init_preprocessor(self):
        if self.input_files is None or 'trade_file' not in self.input_files:
            raise SemanticException("A valid 'trafe_file' must be specified in the input_files section for pre-processing class {}".format(self.__class__.__name__))

    def run_preprocessor(self):
        """Expected file format: CSV with following fields

        - date: date of the movement (ISO format)
        - source: ID of the source herd
        - dest: ID of the dest herd
        - age: age group of the animals to move
        - quantity: amount of animals to move
        """
        if 'moves' not in self.simulation.shared_data:
            debuginfo('Reading {}'.format(self.input_files.trade_file))
            self.simulation.shared_data['moves'] = self.restructure_moves()
        else:
            debuginfo('Trade movements already loaded in simulation')

    def restructure_moves(self):
        """Restructure the CSV file as nested dictionaries"""

        # read a CSV data file for moves:
        # date of movement, source herd, destination herd, age group, quantity

        # and restructure it according to origin_date and delta_t:
        # {step: {source_id: [(dest_id, age_group, qty), ...],
        #         ...},
        #  ...}
        origin = self.model.origin_date
        step_duration = self.model.step_duration
        moves = {}
        with open(self.input_files.trade_file) as csvfile:
            # read the CSV file
            csvreader = csv.DictReader(csvfile, delimiter=',')
            for row in csvreader:
                day = dup.parse(row['date'])
                if day < origin:
                    # ignore dates before origin_date
                    continue
                # convert dates into simulation steps
                step = (day - origin) // step_duration
                # group information by step and source herd
                if step not in moves:
                    moves[step] = {}
                src, dest, qty = int(row['source']), int(row['dest']), int(row['qty'])
                if src not in moves[step]:
                    moves[step][src] = []
                moves[step][src].append([dest, row['age'], qty])
        return moves


#===============================================================
# CLASS Metapopulation (LEVEL 'metapop')
#===============================================================
class Metapopulation(MetapopProcessManager):
    """
    level of the metapop.

    """

    #----------------------------------------------------------------
    # Processes
    #----------------------------------------------------------------
    def exchange_animals(self):
        """

        => INDICATE HERE HOW TO PERFORM PROCESS exchange_animals.
        """
        moves = self.simulation.shared_data['moves']
        if self.statevars.step in moves:
            herds = self.get_populations()
            for source in moves[self.statevars.step]:
                for dest, age, qty in moves[self.statevars.step][source]:
                    # neither source/dest in simulated herds
                    if (source not in herds) and (dest not in herds):
                        # debuginfo('ignoring movement from {} to {} (outside the metapopulation)'.format(source, dest))
                        continue
                    # source not in simulated herds: create animal from prototype
                    if source not in herds:
                        # debuginfo('movement to {} coming from outside the metapopulation'.format(dest))

                        # retrieve prototype definition from the model
                        prototype = self.model.get_prototype(name='imported_animal', level='animals')
                        # change age group to comply with movement
                        prototype['age_group'] = self.get_model_value(age)
                        animals = [herds[dest].new_atom(custom_prototype=prototype)
                                   for _ in range(qty)]
                        # debuginfo('importing', animals)
                    else:
                        # find convenient animals
                        candidates = herds[source].select_atoms('age_group', age)
                        # try to move the appropriate quantity
                        nb = min(len(candidates), qty)
                        animals = np.random.choice(candidates, nb, replace=False)
                        herds[source].remove_atoms(animals)
                        # debuginfo('removing', animals, 'from', source)
                        # update variable 'sold' in source herd
                        herds[source].statevars.sold += len(animals)
                    if dest not in herds:
                        # debuginfo('movement from {} going outside the metapopulation'.format(source))
                        pass
                    else:
                        herds[dest].add_atoms(animals)
                        # update variable 'purchased' in dest herd
                        herds[dest].statevars.purchased += len(animals)
                        # debuginfo('adding', animals, 'to', dest)
