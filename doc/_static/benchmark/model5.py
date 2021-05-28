"""
Python add-on for model 5 (Epidemiological Benchmark)
"""

import numpy                 as     np

from emulsion.agent.managers import MetapopProcessManager
from emulsion.agent.views import AutoStructuredView
from emulsion.agent.managers import MultiProcessManager
from emulsion.agent.views import SimpleView
from emulsion.agent.atoms import AtomAgent


#===============================================================
# CLASS Metapop (LEVEL 'metapop')
#===============================================================
class Metapop(MetapopProcessManager):
    """
    level of the metapopulation.

    """

    #----------------------------------------------------------------
    # Processes
    #----------------------------------------------------------------

    def host_trade(self):
        """Proceed to host moves from source populations to dest
        populations.

        """
        populations = self.get_populations()
        for pop in populations.values():
            outgoing = pop.get_outbox()
            if outgoing:
                for message in outgoing:
                    populations[message['dest']].add_inbox([message])


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
        # retrieve model parameters
        nb_pop = int(self.get_model_value('nb_populations'))
        p_move = self.get_model_value('p_move')
        # select randomly hosts to sell among hosts only
        hosts = self.select_atoms(variable='species', state='H')
        nb_to_sell = np.random.binomial(len(hosts), p_move)
        if nb_to_sell > 0:
            np.random.shuffle(hosts)
            to_sell = hosts[:nb_to_sell]
            nb_left = np.random.binomial(len(to_sell), 0.5)
            # select hosts going to each neighbour population
            left_pop, right_pop = to_sell[:nb_left], to_sell[nb_left:]
            left_id = (self.statevars.population_id - 1 + nb_pop) % nb_pop
            right_id = (self.statevars.population_id + 1) % nb_pop
            # create new messages
            if left_pop:
                self.add_outbox({'src': self.statevars.population_id,
                                 'dest': left_id,
                                 'hosts': left_pop })
            if right_pop:
                self.add_outbox({'src': self.statevars.population_id,
                                 'dest': right_id,
                                 'hosts': right_pop })
            # remove host from current population
            self.remove_atoms(to_sell)
