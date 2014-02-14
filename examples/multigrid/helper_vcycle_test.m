function [u] = helper_vcycle_test(Mc, Lc, Ec, V, F, TMf2c, TMc2f, BAND, BOUNDARY, n1, n2, start, w)

% V: a vector storing solution vectors of each V-cycle level
% M: a matrix storing iterative matrices of each V-cycle level
% F: a vector storing the right hand side (residual) of each V-cycle level
% TMf2c:   transform matrices from fine grid to coarse grid
% TMc2f:   transform matrices from coarse grid to fine grid
% p:  degree of interpolation polynomial
% n1: number of gauss-seidel iterations of the downward branch of the V-cycle
% n2: number of gauss-seidel iterations of the upward branch of the V-cycle

% number of the levels of multigrid
n_level = length(BAND);

% seems to improve the solution of semicircle or hemisphere dealing with
% Dirichlet Boundary condtion
% V{1} = Ec{1}*V{1};

% downward branch of the V-cycle
for i = start:1:n_level-1
    
    for j = 1:1:n1
        %V{i} = gauss_seidel(Lc{i}, V{i}, F{i});
        V{i} = jacobi(Lc{i}, V{i}, F{i});
        V{i} = Ec{i}*V{i};
        %V{i} = V{i} + (F{i} - Ec{i}*(Lc{i}*V{i})) ./ diag(Lc{i});
        V{i} = V{i} - sum(V{i})/length(V{i})*ones(size(V{i}));
    end

    % need do extension to ensure res along normal direction constant ?
    %res = F{i} - Ec{i}*(Lc{i}*V{i});    
    res = F{i} - (Lc{i}*V{i});
    
    F{i+1} = TMf2c{i}*res;
    
    % since the original rhs is constant along the normal direction, we
    % hope to keep this property at each level of V-Cycle, sometimes this
    % would make multigrid converge faster, but sometimes less accurate
    % F{i+1} = Ec{i+1}*F{i+1};    
end

% solve on the coarsest grid
if isa(Mc, 'cell')
    %i = n_level;
    %F_long = [F{i}; zeros(size(F{i}))];
    %lambda = 4/0.2^2;
    %Mc_rect = [Ec{i}*Lc{i}; lambda*(speye(size(Ec{i}))-Ec{i})];
    %V{n_level} = Mc_rect \ F_long;
    V{n_level} = Mc{n_level} \ F{n_level};
    %V{n_level} = Ec{n_level}*V{n_level};
    %[V{n_level} flag] = gmres(Mc{n_level}, F{n_level}, [], 1e-6);
else
    %V{n_level} = Mc \ F{n_level};
    [V{n_level} flag] = gmres(Mc, F{n_level}, [], 1e-6);
end
% [V{n_level} flag] = gmres(Mc{n_level}, F{n_level}, [], 1e-10);
% [V{n_level} flag] = gmres(Mc{n_level}, F{n_level}, 5, 1e-6);

% upward branch of the V-cycle
for i = n_level-1:-1:start   
    
    v = TMc2f{i}*V{i+1};
    % here Ec{i}*v will improve the accuracy when using the Crank-Nicolson
    % Scheme; and Ec{i}*v is essentially neccessary in solving poisson
    % euqation on a semicircle with Nuemann Boundary condition:
    V{i} = V{i} + Ec{i}*v;
    %V{i} = V{i} + v;
    for j = 1:n2
        % we should use Ec{i}*V{i} as the initial value
        %V{i} = gauss_seidel(Lc{i}, V{i}, F{i});
        V{i} = jacobi(Lc{i}, V{i}, F{i});
        V{i} = Ec{i}*V{i};        
        %V{i} = V{i} + (F{i} - Ec{i}*(Lc{i}*V{i})) ./ diag(Lc{i});        
        V{i} = V{i} - sum(V{i})/length(V{i})*ones(size(V{i}));
    end

end

u = V{start};

end