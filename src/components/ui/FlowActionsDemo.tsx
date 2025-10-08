import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './card';
import { Button } from './button';
import { Input } from './input';
import { Label } from './label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './select';
import { Badge } from './badge';
import { Separator } from './separator';
import { flowActionsClient } from '../../actions/FlowActionsClient';
import { toast } from 'sonner';

interface FlowActionsDemoProps {
  userAddress?: string;
}

export function FlowActionsDemo({ userAddress }: FlowActionsDemoProps) {
  const [isLoading, setIsLoading] = useState(false);
  const [operationId, setOperationId] = useState<string>('');
  
  // Composable Swap State
  const [swapTokenIn, setSwapTokenIn] = useState('FLOW');
  const [swapTokenOut, setSwapTokenOut] = useState('TEST');
  const [swapAmount, setSwapAmount] = useState('1.0');
  const [minOutput, setMinOutput] = useState('0.9');
  
  // Recurring Swap State
  const [recurringTokenIn, setRecurringTokenIn] = useState('FLOW');
  const [recurringTokenOut, setRecurringTokenOut] = useState('TEST');
  const [recurringAmount, setRecurringAmount] = useState('0.5');
  const [intervalHours, setIntervalHours] = useState('24');
  const [maxRecurrences, setMaxRecurrences] = useState('10');

  const handleCreateUniqueId = async () => {
    if (!userAddress) {
      toast.error('Please connect your wallet first');
      return;
    }

    setIsLoading(true);
    try {
      const id = await flowActionsClient.createUniqueIdentifier();
      setOperationId(id);
      toast.success(`Unique ID created: ${id}`);
    } catch (error) {
      console.error('Error creating unique ID:', error);
      toast.error('Failed to create unique ID');
    } finally {
      setIsLoading(false);
    }
  };

  const handleComposableSwap = async () => {
    if (!userAddress) {
      toast.error('Please connect your wallet first');
      return;
    }

    setIsLoading(true);
    try {
      const result = await flowActionsClient.executeComposableSwap(
        swapTokenIn,
        swapTokenOut,
        parseFloat(swapAmount),
        parseFloat(minOutput),
        userAddress
      );
      
      toast.success('Composable swap executed successfully!');
      console.log('Swap result:', result);
    } catch (error) {
      console.error('Error executing composable swap:', error);
      toast.error('Failed to execute composable swap');
    } finally {
      setIsLoading(false);
    }
  };

  const handleScheduleRecurringSwap = async () => {
    if (!userAddress) {
      toast.error('Please connect your wallet first');
      return;
    }

    setIsLoading(true);
    try {
      const intervalSeconds = parseFloat(intervalHours) * 3600; // Convert hours to seconds
      
      const result = await flowActionsClient.scheduleRecurringSwap(
        recurringTokenIn,
        recurringTokenOut,
        parseFloat(recurringAmount),
        intervalSeconds,
        userAddress
      );
      
      toast.success('Recurring swap scheduled successfully!');
      console.log('Schedule result:', result);
    } catch (error) {
      console.error('Error scheduling recurring swap:', error);
      toast.error('Failed to schedule recurring swap');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreateVaultSource = async () => {
    if (!userAddress) {
      toast.error('Please connect your wallet first');
      return;
    }

    setIsLoading(true);
    try {
      const result = await flowActionsClient.createVaultSource(
        swapTokenIn,
        0.0, // Minimum amount
        userAddress
      );
      
      toast.success('Vault source created successfully!');
      console.log('Vault source result:', result);
    } catch (error) {
      console.error('Error creating vault source:', error);
      toast.error('Failed to create vault source');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreateVaultSink = async () => {
    if (!userAddress) {
      toast.error('Please connect your wallet first');
      return;
    }

    setIsLoading(true);
    try {
      const result = await flowActionsClient.createVaultSink(
        swapTokenOut,
        null, // No maximum limit
        userAddress
      );
      
      toast.success('Vault sink created successfully!');
      console.log('Vault sink result:', result);
    } catch (error) {
      console.error('Error creating vault sink:', error);
      toast.error('Failed to create vault sink');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <span className="text-2xl">⚡</span>
            Flow Actions Demo
          </CardTitle>
          <CardDescription>
            Composable DeFi operations with Flow Actions pattern
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-4">
            <Badge variant={userAddress ? "default" : "secondary"}>
              {userAddress ? `Connected: ${userAddress.slice(0, 8)}...` : 'Not Connected'}
            </Badge>
            {operationId && (
              <Badge variant="outline">
                Operation ID: {operationId.slice(0, 12)}...
              </Badge>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Unique Identifier */}
      <Card>
        <CardHeader>
          <CardTitle>🆔 Unique Identifier</CardTitle>
          <CardDescription>
            Create a unique identifier for tracing operations
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button 
            onClick={handleCreateUniqueId}
            disabled={isLoading || !userAddress}
            className="w-full"
          >
            {isLoading ? 'Creating...' : 'Create Unique ID'}
          </Button>
        </CardContent>
      </Card>

      {/* Composable Swap */}
      <Card>
        <CardHeader>
          <CardTitle>🔄 Composable Swap</CardTitle>
          <CardDescription>
            Execute a swap using Flow Actions Source/Sink pattern
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="swap-token-in">Token In</Label>
              <Select value={swapTokenIn} onValueChange={setSwapTokenIn}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="FLOW">FLOW</SelectItem>
                  <SelectItem value="TEST">TEST</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="swap-token-out">Token Out</Label>
              <Select value={swapTokenOut} onValueChange={setSwapTokenOut}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="FLOW">FLOW</SelectItem>
                  <SelectItem value="TEST">TEST</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="swap-amount">Amount In</Label>
              <Input
                id="swap-amount"
                type="number"
                step="0.1"
                value={swapAmount}
                onChange={(e) => setSwapAmount(e.target.value)}
                placeholder="1.0"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="min-output">Min Output</Label>
              <Input
                id="min-output"
                type="number"
                step="0.1"
                value={minOutput}
                onChange={(e) => setMinOutput(e.target.value)}
                placeholder="0.9"
              />
            </div>
          </div>

          <div className="flex gap-2">
            <Button 
              onClick={handleComposableSwap}
              disabled={isLoading || !userAddress}
              className="flex-1"
            >
              {isLoading ? 'Executing...' : 'Execute Composable Swap'}
            </Button>
            <Button 
              variant="outline"
              onClick={handleCreateVaultSource}
              disabled={isLoading || !userAddress}
            >
              Create Source
            </Button>
            <Button 
              variant="outline"
              onClick={handleCreateVaultSink}
              disabled={isLoading || !userAddress}
            >
              Create Sink
            </Button>
          </div>
        </CardContent>
      </Card>

      <Separator />

      {/* Recurring Swap */}
      <Card>
        <CardHeader>
          <CardTitle>🔁 Recurring Swap</CardTitle>
          <CardDescription>
            Schedule recurring swaps using Flow Callbacks
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="recurring-token-in">Token In</Label>
              <Select value={recurringTokenIn} onValueChange={setRecurringTokenIn}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="FLOW">FLOW</SelectItem>
                  <SelectItem value="TEST">TEST</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="recurring-token-out">Token Out</Label>
              <Select value={recurringTokenOut} onValueChange={setRecurringTokenOut}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="FLOW">FLOW</SelectItem>
                  <SelectItem value="TEST">TEST</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          
          <div className="grid grid-cols-3 gap-4">
            <div className="space-y-2">
              <Label htmlFor="recurring-amount">Amount</Label>
              <Input
                id="recurring-amount"
                type="number"
                step="0.1"
                value={recurringAmount}
                onChange={(e) => setRecurringAmount(e.target.value)}
                placeholder="0.5"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="interval-hours">Interval (hours)</Label>
              <Input
                id="interval-hours"
                type="number"
                step="1"
                value={intervalHours}
                onChange={(e) => setIntervalHours(e.target.value)}
                placeholder="24"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="max-recurrences">Max Recurrences</Label>
              <Input
                id="max-recurrences"
                type="number"
                step="1"
                value={maxRecurrences}
                onChange={(e) => setMaxRecurrences(e.target.value)}
                placeholder="10"
              />
            </div>
          </div>

          <Button 
            onClick={handleScheduleRecurringSwap}
            disabled={isLoading || !userAddress}
            className="w-full"
          >
            {isLoading ? 'Scheduling...' : 'Schedule Recurring Swap'}
          </Button>
        </CardContent>
      </Card>

      {/* Info Card */}
      <Card>
        <CardHeader>
          <CardTitle>ℹ️ Flow Actions Features</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2 text-sm text-muted-foreground">
            <p>• <strong>Composable Operations:</strong> Chain multiple DeFi operations atomically</p>
            <p>• <strong>Source/Sink Pattern:</strong> Standardized token input/output handling</p>
            <p>• <strong>Scheduled Callbacks:</strong> Automated recurring operations</p>
            <p>• <strong>Unique Tracing:</strong> Track operations across the entire flow</p>
            <p>• <strong>Error Handling:</strong> Robust failure recovery and rollback</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}