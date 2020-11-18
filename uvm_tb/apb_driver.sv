`define DRIVAPB_IF vifapb.DRIVER.driver_cb

class apb_driver extends uvm_driver #(apb_transaction);
	logic [5:0]		bcount = 0;
  
	virtual apb_if	vifapb;
  	`uvm_component_utils(apb_driver)
    
	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new
  
  	uvm_analysis_port #(apb_transaction) item_collected_port_drv;
  
  	// ------------------------------------------------------------------------
  	// The following property holds the transaction information currently
  	// begin captured by monitor run phase and make it one transaction.
  	// ------------------------------------------------------------------------
  	apb_transaction trans_collected_drv; 

	uvm_analysis_port #(apb_transaction) item_collected_port;
  	apb_transaction trans_collected; 

  	//--------------------------------------- 
  	// build phase
  	//---------------------------------------
  	function void build_phase(uvm_phase phase);
  		super.build_phase(phase);
  	   	if(!uvm_config_db#(virtual apb_if)::get(this, "", "vifapb", vifapb))
  	    	`uvm_fatal("NO_VIF",{"virtual interface must be set for: ",get_full_name(),".vifapb"});
      	trans_collected_drv = new();
      	item_collected_port_drv = new("item_collected_port_drv", this);
  	endfunction: build_phase

  	//---------------------------------------  
  	// run phase
  	//---------------------------------------  
  	virtual task run_phase(uvm_phase phase);
  		apb_transaction req;
  	  	forever 
  	  	begin
  	    	@(posedge vifapb.PCLK iff (vifapb.PRESETn))
  	    	seq_item_port.get_next_item(req);
  	    	drive(req);
  	    	seq_item_port.item_done();
  	  	end
  	endtask : run_phase
	
  	//---------------------------------------
  	// drive - transaction level to signal level
  	// drives the value's from seq_item to interface signals
  	//---------------------------------------
	
  	virtual task drive(apb_transaction req);
  		`DRIVAPB_IF.PSELx		<= 0;
		`DRIVAPB_IF.PENABLE		<= 0;  
		`DRIVAPB_IF.PWRITE		<= 0;
  	  	`DRIVAPB_IF.PWDATA		<= 0;
  	  	`DRIVAPB_IF.PADDR		<= 0;	
  	  	repeat(2)@(posedge vifapb.DRIVER.PCLK);
  	  	if(req.PADDR == 0 || req.PADDR == 1 || req.PADDR == 2 || req.PADDR == 3 || req.PADDR == 4) 
  	  	begin
			`DRIVAPB_IF.PSELx			<= 1;
			@(posedge vifapb.DRIVER.PCLK);
			`DRIVAPB_IF.PENABLE			<= 1;
  	  	    `DRIVAPB_IF.PWRITE			<= req.PWRITE;
  	  	    `DRIVAPB_IF.PWDATA			<= req.PWDATA;
  	  	    `DRIVAPB_IF.PADDR			<= req.PADDR;
			trans_collected_drv.PADDR 	 = req.PADDR;
			trans_collected_drv.PWDATA 	 = req.PWDATA;
			//$display("Address in Transaction = %d" , trans_collected_drv.PADDR);
			 wait(`DRIVAPB_IF.PREADY);		
			`DRIVAPB_IF.PSELx			<= 0;
			`DRIVAPB_IF.PENABLE			<= 0;
			//wait(!`DRIVAPB_IF.PREADY);
			//$display("Address in Transaction = %d" , trans_collected_drv.PADDR);
  	  	end
 		else if(req.PADDR == 5)
  	  	begin
			`DRIVAPB_IF.PSELx		<= 1;
			@(posedge vifapb.DRIVER.PCLK);
			`DRIVAPB_IF.PENABLE		<= 1;
  	  	    `DRIVAPB_IF.PWRITE		<= req.PWRITE;
  	  	    `DRIVAPB_IF.PWDATA		<= req.PWDATA;
  	  	    `DRIVAPB_IF.PADDR		<= req.PADDR;
  	  	end
		item_collected_port_drv.write(trans_collected_drv); // It sends the transaction non-blocking and it
  	endtask
endclass
