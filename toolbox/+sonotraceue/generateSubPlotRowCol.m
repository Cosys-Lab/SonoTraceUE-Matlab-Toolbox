function [rows, cols, N] = generateSubPlotRowCol(N, maxNum)
  N = double(N);
  N = max(1, round(N));
  N = min(N, maxNum);
  if N <= 4
    cols = N;
    rows = 1;
  else
    cols = min(4, ceil(sqrt(N)));
    rows = ceil(N / cols);
  end
end