#!/usr/bin/env python3
"""
构建进化树 (Neighbor-Joining算法)
使用距离矩阵
"""

import sys

def read_distance_matrix(mdist_file, id_file):
    """Read PLINK distance matrix"""
    # Read IDs
    ids = []
    with open(id_file, 'r') as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 2:
                ids.append(parts[1])  # IID
    
    # Read distance matrix
    matrix = []
    with open(mdist_file, 'r') as f:
        for line in f:
            row = [float(x) for x in line.strip().split()]
            matrix.append(row)
    
    return ids, matrix

def neighbor_joining(ids, dist_matrix):
    """
    Simplified Neighbor-Joining algorithm
    Returns Newick format tree string
    """
    n = len(ids)
    
    # Make copies
    active_ids = list(ids)
    active_matrix = [row[:] for row in dist_matrix]
    
    # Keep track of tree structure
    nodes = {i: (active_ids[i], 0) for i in range(n)}  # (name, branch_length)
    
    while len(active_ids) > 2:
        m = len(active_ids)
        
        # Calculate Q matrix
        q_matrix = [[0] * m for _ in range(m)]
        for i in range(m):
            for j in range(i+1, m):
                # Calculate sum of distances for each row
                r_i = sum(active_matrix[i][k] for k in range(m) if k != i)
                r_j = sum(active_matrix[j][k] for k in range(m) if k != j)
                
                # Q value
                q_matrix[i][j] = q_matrix[j][i] = (m - 2) * active_matrix[i][j] - r_i - r_j
        
        # Find minimum Q value
        min_q = float('inf')
        min_i, min_j = 0, 1
        for i in range(m):
            for j in range(i+1, m):
                if q_matrix[i][j] < min_q:
                    min_q = q_matrix[i][j]
                    min_i, min_j = i, j
        
        # Merge nodes min_i and min_j
        # Calculate branch lengths (simplified)
        branch_length = active_matrix[min_i][min_j] / 2
        
        # Create new node
        new_name = f"({active_ids[min_i]}:{branch_length:.4f},{active_ids[min_j]}:{branch_length:.4f})"
        
        # Update distance matrix (simplified)
        new_row = []
        for k in range(m):
            if k != min_i and k != min_j:
                new_dist = (active_matrix[min_i][k] + active_matrix[min_j][k]) / 2
                new_row.append(new_dist)
        
        # Remove merged rows/columns and add new row
        # Remove in reverse order to maintain indices
        for idx in sorted([min_i, min_j], reverse=True):
            active_matrix.pop(idx)
            active_ids.pop(idx)
        
        for i in range(len(active_matrix)):
            for idx in sorted([min_i, min_j], reverse=True):
                active_matrix[i].pop(idx)
        
        # Add new row and column
        active_ids.append(new_name)
        new_matrix = [row[:] for row in active_matrix]
        for i in range(len(new_matrix)):
            new_matrix[i].append(new_row[i])
        new_row.append(0)
        new_matrix.append(new_row)
        active_matrix = new_matrix
    
    # Final merge
    if len(active_ids) == 2:
        final_dist = active_matrix[0][1] / 2
        tree = f"({active_ids[0]}:{final_dist:.4f},{active_ids[1]}:{final_dist:.4f});"
    else:
        tree = f"{active_ids[0]};"
    
    return tree

def write_newick(tree, output_file):
    """Write Newick format tree to file"""
    with open(output_file, 'w') as f:
        f.write(tree + '\n')

def main():
    if len(sys.argv) < 4:
        print("Usage: python3 build_tree.py <mdist_file> <id_file> <output_newick>")
        sys.exit(1)
    
    mdist_file = sys.argv[1]
    id_file = sys.argv[2]
    output_file = sys.argv[3]
    
    print("Reading distance matrix...")
    ids, matrix = read_distance_matrix(mdist_file, id_file)
    print(f"Loaded {len(ids)} samples")
    
    print("Building neighbor-joining tree...")
    tree = neighbor_joining(ids, matrix)
    
    print(f"Writing tree to {output_file}")
    write_newick(tree, output_file)
    print("Done!")

if __name__ == "__main__":
    main()
