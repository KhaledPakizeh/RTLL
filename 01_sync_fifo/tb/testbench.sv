always @(posedge clk) begin
    if (rst) begin
        queue.delete();
        check_pending <= 0;
    end else begin
        // 1. compare data from the read accepted on the previous edge
        if (check_pending) begin
            if (d_out !== data_expected) begin
                errors++;
                $error("[%0t] d_out=%0h expected %0h", $time, d_out, data_expected);
            end
        end
        check_pending <= 0;

        // 2. flags vs model (state before this edge)
        size_before = queue.size();
        if (full  !== (size_before == DEPTH)) begin errors++; $error("full wrong, size=%0d",  size_before); end
        if (empty !== (size_before == 0))     begin errors++; $error("empty wrong, size=%0d", size_before); end

        // 3. update model; both decisions use size_before
        if (read_enable && size_before > 0) begin
            data_expected <= queue.pop_front();
            check_pending <= 1;
        end
        if (write_enable && size_before < DEPTH)
            queue.push_back(d_in);
    end
end
