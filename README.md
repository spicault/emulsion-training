# Introduction to the exploration of epidemiological models using EMULSION

| Author: **Sébastien Picault, INRAE** | June 2-4, 2021 |
|---|---|
| License: [CC-BY-NC-SA](https://en.wikipedia.org/wiki/Creative_Commons_license) | ![CC-BY-NC-SA](https://upload.wikimedia.org/wikipedia/commons/1/12/Cc-by-nc-sa_icon.svg "License CC-BY-NC-SA") |

This training is part of the doctoral formation proposed at the EGAAL doctoral school.

## Configuration

Exercises can be run either on your own machine on through a virtual environment provided by [Binder](https://mybinder.readthedocs.io/en/latest/).

### Solution 1: do everything on-line

We provide a pre-configured virtual environment thanks to Binder, which ensures that all participants work with the same software environment. 

This on-line environment can be launched by clicking this button: [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/git/https%3A%2F%2Fforgemia.inra.fr%2FSebastien.Picault%2Femulsion-training/HEAD?urlpath=lab)

**IMPORTANT NOTES:**

- At the very first time, Binder has to build the virtual environment before launching it, which takes some time (about 10 minutes). After that, the Binder environment is cached, hence taking only 1-2 min to launch
- The Binder environment is **ephemeral**, with a short timeout period (about 10 min). Thus, you have to periodically save (download) the files you modify (e.g. EMULSION model files, or possibly the notebook), to be able to restore them after a break.

### Solution 2: install on your own machine

Choose this approach if you are already familiar with software installation on your machine.

- Download this repository (see button above) or clone it with `git` (`git clone https://forgemia.inra.fr/Sebastien.Picault/emulsion-training.git`)
- Install and test EMULSION version **1.2b1** (with Graphviz) on your own machine following the [installation instructions](https://sourcesup.renater.fr/www/emulsion-public/pages/Install.html) and the [section regarding development versions](https://sourcesup.renater.fr/www/emulsion-public/pages/Install.html#alternative-2-install-development-version).
- For the exercises, follow the instructions provided in the notebook [Getting started](Getting%20started.ipynb). By default, this notebook will be displayed in a read-only mode. To have it work interactively, you need to install [Jupyter lab](https://jupyter.org/) on your machine.
- To run the exercises themselves, copy-paste commands in your favourite terminal.

## Additional resources

- [EMULSION website](https://sourcesup.renater.fr/www/emulsion-public) and [software paper](https://doi.org/10.1371/journal.pcbi.1007342)
- [DYNAMO team](https://www6.angers-nantes.inrae.fr/bioepar/Equipes/DYNAMO)
- follow us: [`@bioepar_dynamo`](https://twitter.com/bioepar_dynamo)
