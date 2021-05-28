"""
Python add-on for model 6 (Epidemiological Benchmark)
"""

from   pathlib               import Path
import csv
import dateutil.parser       as     dup
import numpy                 as     np

from emulsion.agent.managers import MetapopProcessManager
from emulsion.agent.views import AutoStructuredView
from emulsion.agent.managers import MultiProcessManager
from emulsion.agent.views import SimpleView
from emulsion.agent.atoms import AtomAgent

DATA_FILE = 'moves.csv'

#===============================================================
# CLASS Metapop (LEVEL 'metapop')
#===============================================================
class Metapop(MetapopProcessManager):
    """
    level of the metapopulation.

    """
    #----------------------------------------------------------------
    # Level initialization
    #----------------------------------------------------------------
    def initialize_level(self, **others):
        """Initialize an instance of Metapopulation: reads the CSV file for
        movements and restructure it according to simulation time.

        """
        # read a CSV data file for moves:
        # date of movement, source herd, destination herd, age group, quantity

        # and restructure it according to origin_date and delta_t:
        # {step: {source_id: [(dest_id, age_group, qty), ...],
        #         ...},
        #  ...}
        origin = self.model.origin_date
        step_duration = self.model.step_duration
        moves = {}
        with open(Path(self.model.input_dir, DATA_FILE)) as csvfile:
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
        self.moves = moves

    #----------------------------------------------------------------
    # Processes
    #----------------------------------------------------------------

    def host_trade(self):
        """Proceed to host moves from source populations to dest
        populations. Now the system is not closed, thus individuals
        can be sent outside the metapopulation (dest ID does not
        correspond to an existing population) or come from outside the
        metapopulation (src ID in events does not correspond to an
        existing population).

        """
        populations = self.get_populations()
        # transmit messages from source populations
        for pop in populations.values():
            outgoing = pop.get_outbox()
            if outgoing:
                for message in outgoing:
                    dest_ID = message['dest']
                    if dest_ID in populations:
                        # dest population in the metapop
                        populations[dest_ID].add_inbox([message])
                        # otherwise individuals are just "lost"
        # search for individuals coming from outside the metapopulation
        if self.statevars.step in self.moves:
            moves = self.moves[self.statevars.step]
            outside_id = [src_id for src_id in moves
                          if src_id not in populations]
            p_infected = self.get_model_value('external_risk')
            for src_id in outside_id:
                for dest, age, qty in moves[src_id]:
                    # ignore movements to other populations ouside the
                    # metapopulation
                    if dest not in populations:
                        continue
                    # create new individuals matching the specifications
                    # retrieve prototype definitions from the model
                    proto_S = self.model.get_prototype(name='imported_S_host', level='individuals', simu_id=self.statevars.simu_id)
                    proto_I = self.model.get_prototype(name='imported_I_host', level='individuals', simu_id=self.statevars.simu_id)
                    # change age group to comply with movement
                    proto_S['age_group'] = self.get_model_value(age)
                    proto_I['age_group'] = self.get_model_value(age)
                    nb_S, nb_I = np.random.multinomial(qty, [1-p_infected, p_infected])
                    new_individuals = [populations[dest].new_atom(custom_prototype=proto_S)
                                       for _ in range(nb_S)] +\
                                      [populations[dest].new_atom(custom_prototype=proto_I)
                                       for _ in range(nb_I)]
                    # send message to dest
                    populations[dest].add_inbox([{'src': src_id,
                                                  'dest': dest,
                                                  'hosts': new_individuals}])


#===============================================================
# CLASS Population (LEVEL 'population')
#===============================================================
class Population(MultiProcessManager):
    """
    level of the population.
    """

    #----------------------------------------------------------------
    # Processes
    #----------------------------------------------------------------

    def integrate_purchased_hosts(self):
        """Check incoming hosts (put in 'inbox') and add them to local
        population.

        """
        # collect incoming hosts from 'inbox'
        purchased = []
        for message in self._inbox:
            if 'hosts' in message:
                purchased += message['hosts']
        if purchased:
            self.add_atoms(purchased)
        self.clean_inbox()


    def select_sold_hosts(self):
        """Select hosts to be sold and move them to 'outbox'.

        """
        # clean outgoing messages
        self.reset_outbox()
        # check if something to do at current time step for this population
        step = self.statevars.step
        my_id = self.statevars.population_id
        all_moves = self.upper_level().moves
        if step in all_moves:
            if my_id in all_moves[step]:
                my_moves = all_moves[step][my_id]
                for dest, age, qty in my_moves:
                    # find convenient animals
                    candidates = self.select_atoms('age_group', age, process='aging')
                    # try to move the appropriate quantity
                    nb = min(len(candidates), qty)
                    np.random.shuffle(candidates)
                    removed = candidates[:nb]
                    self.add_outbox({'src': my_id,
                                     'dest': dest,
                                     'hosts': removed })
                    self.remove_atoms(removed)
