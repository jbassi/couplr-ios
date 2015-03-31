import numpy as np
import networkx as nx
import matplotlib.pyplot as plt
import os
from util import *

def first_name_last_initial(name):
    name = name.split(" ")
    return name[0] + " " + name[-1][0] + "."

sigma = lambda x: 1. / (1. + np.exp(-x))

def label_position(position):
    return position - np.array([0, 0.01])

def edge_weight_baseline(socialGraph, root):
    totalWeight = 0
    numEdges = 0
    for u, v in socialGraph.edges():
        totalWeight += socialGraph[u][v]["weight"]
        numEdges += 1
    weightFromRoot = sum([v["weight"] for v in socialGraph[root].values()])
    return (totalWeight - weightFromRoot) / (numEdges - len(socialGraph[root]))

def nx_graph_from_data(data):
    graph = nx.Graph()
    for node, neighbors in data["edges"].items():
        for neighbor, weight in neighbors.items():
            if node < neighbor:
                graph.add_edge(node, neighbor, weight=data["edges"][node][neighbor])
    return graph

def save_graph_as_image(graphName):
    data = load_json_as_object("data/" + graphName)
    graph = nx_graph_from_data(data)
    nodes, edges = data["nodes"], data["edges"]

    plt.figure(figsize=(16, 16))
    positions = nx.spring_layout(graph, k=1.5/np.sqrt(len(nodes)), iterations=500)
    nx.draw_networkx_nodes(graph, positions, nodes.keys(), node_color="r", node_size=25, alpha=0.9)

    baseline = edge_weight_baseline(graph, data["root"])
    edgeWeights = [sigma(graph[u][v]["weight"] - baseline) for u, v in graph.edges()]

    nx.draw_networkx_edges(graph, positions, width=1, alpha=0.35, edge_color=edgeWeights, edge_cmap=plt.get_cmap("jet"))
    nx.draw_networkx_labels(graph, {u: label_position(p) for u, p in positions.items()},
        {u: first_name_last_initial(nodes[u]) for u in nodes}, font_size=8)
    plt.axis("off")
    imageName = "images/" + graphName + ".png"
    plt.savefig(imageName, dpi=255)
    os.popen("open " + imageName)
    return graph

if __name__ == "__main__":
    graph = save_graph_as_image("10204809301328264")
