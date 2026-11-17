using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;

namespace HiOP.WinUI3.Services;

public sealed class NativeStageService : IDisposable
{
    private const string DllName = "LoopingStageCore.dll";

    public const uint InputLeft = 1u << 0;
    public const uint InputRight = 1u << 1;
    public const uint InputUp = 1u << 2;
    public const uint InputDown = 1u << 3;
    public const uint InputJump = 1u << 4;
    public const uint InputShoot = 1u << 5;
    public const uint InputDash = 1u << 6;
    public const uint InputSprint = 1u << 7;

    private static bool _resolverRegistered;
    private static string? _resolvedDllPath;
    private readonly object _sync = new();
    private int _handle;
    private bool _disposed;

    static NativeStageService()
    {
        EnsureResolverRegistered();
    }

    public static string? ResolveLibraryPath(string? engineRepoRoot = null)
    {
        if (!string.IsNullOrEmpty(_resolvedDllPath) && File.Exists(_resolvedDllPath))
            return _resolvedDllPath;

        var candidates = new List<string>
        {
            Path.Combine(AppContext.BaseDirectory, "Assets", "Native", DllName),
            Path.Combine(AppContext.BaseDirectory, DllName),
            Path.Combine(AppContext.BaseDirectory, "bin", DllName)
        };

        if (!string.IsNullOrWhiteSpace(engineRepoRoot))
        {
            candidates.Add(Path.Combine(engineRepoRoot, "build", "win", DllName));
            candidates.Add(Path.Combine(engineRepoRoot, "bin", DllName));
        }

        foreach (var cand in candidates)
        {
            if (File.Exists(cand))
            {
                _resolvedDllPath = cand;
                return cand;
            }
        }
        return null;
    }

    private static void EnsureResolverRegistered()
    {
        if (_resolverRegistered) return;
        _resolverRegistered = true;

        NativeLibrary.SetDllImportResolver(typeof(NativeStageService).Assembly, (libraryName, _, _) =>
        {
            if (!string.Equals(libraryName, DllName, StringComparison.OrdinalIgnoreCase))
                return IntPtr.Zero;

            var path = ResolveLibraryPath();
            if (!string.IsNullOrEmpty(path) && NativeLibrary.TryLoad(path, out var lib))
                return lib;

            return IntPtr.Zero;
        });
    }

    public NativeStageService(string? engineRepoRoot = null)
    {
        ResolveLibraryPath(engineRepoRoot);
    }

    public bool IsNativeCoreAvailable => !string.IsNullOrEmpty(ResolveLibraryPath());

    public void EnsureCreated()
    {
        lock (_sync)
        {
            ObjectDisposedException.ThrowIf(_disposed, this);
            if (_handle <= 0)
            {
                _handle = lp_create();
            }
        }
    }

    public void SetChannel(string channel)
    {
        lock (_sync)
        {
            if (_handle > 0)
                lp_set_channel(_handle, string.IsNullOrWhiteSpace(channel) ? "prod" : channel);
        }
    }

    public string Execute(string code, string channel = "prod")
    {
        lock (_sync)
        {
            EnsureCreated();
            lp_set_channel(_handle, string.IsNullOrWhiteSpace(channel) ? "prod" : channel);
            var ptr = lp_execute(_handle, code ?? string.Empty);
            return PtrToUtf8(ptr) ?? "{}";
        }
    }

    public void SetInput(uint keysMask, double yawDelta = 0.0, double pitchDelta = 0.0)
    {
        lock (_sync)
        {
            if (_handle > 0)
                lp_set_input(_handle, keysMask, yawDelta, pitchDelta);
        }
    }

    public string Step(double dt, double viewW, double viewH)
    {
        lock (_sync)
        {
            if (_handle <= 0) return "{}";
            var ptr = lp_step(_handle, dt, viewW, viewH);
            return PtrToUtf8(ptr) ?? "{}";
        }
    }

    public string GetSnapshotJson(double viewW, double viewH)
    {
        lock (_sync)
        {
            if (_handle <= 0) return "{}";
            var ptr = lp_get_snapshot_json(_handle, viewW, viewH);
            return PtrToUtf8(ptr) ?? "{}";
        }
    }

    public string GetUiJson()
    {
        lock (_sync)
        {
            if (_handle <= 0) return "{}";
            var ptr = lp_get_ui_json(_handle);
            return PtrToUtf8(ptr) ?? "{}";
        }
    }

    public string ClickButton(string actionOrLabel)
    {
        lock (_sync)
        {
            if (_handle <= 0) return "{}";
            var ptr = lp_click_button(_handle, actionOrLabel ?? string.Empty);
            return PtrToUtf8(ptr) ?? "{}";
        }
    }

    public void CycleCamera3D()
    {
        lock (_sync)
        {
            if (_handle > 0)
                lp_cycle_camera3d(_handle);
        }
    }

    public string Restart()
    {
        lock (_sync)
        {
            if (_handle <= 0) return "{}";
            var ptr = lp_restart(_handle);
            return PtrToUtf8(ptr) ?? "{}";
        }
    }

    public bool Render3DBgra(int width, int height, byte[] destBuffer)
    {
        lock (_sync)
        {
            if (_handle <= 0) return false;
            int expected = width * height * 4;
            if (destBuffer.Length < expected) return false;

            var ptr = lp_render_3d_bgra(_handle, width, height);
            if (ptr == IntPtr.Zero) return false;

            Marshal.Copy(ptr, destBuffer, 0, expected);
            return true;
        }
    }

    public void ResetContext()
    {
        lock (_sync)
        {
            if (_handle > 0)
            {
                lp_destroy(_handle);
                _handle = 0;
            }
        }
    }

    private static string? PtrToUtf8(IntPtr ptr)
        => ptr == IntPtr.Zero ? null : Marshal.PtrToStringUTF8(ptr);

    public void Dispose()
    {
        lock (_sync)
        {
            if (_disposed) return;
            _disposed = true;
            if (_handle > 0)
            {
                try { lp_destroy(_handle); } catch { }
                _handle = 0;
            }
        }
    }

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern int lp_create();

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern void lp_destroy(int handle);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern void lp_set_channel(int handle, [MarshalAs(UnmanagedType.LPUTF8Str)] string channel);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern IntPtr lp_execute(int handle, [MarshalAs(UnmanagedType.LPUTF8Str)] string code);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern void lp_set_input(int handle, uint keysMask, double yawDelta, double pitchDelta);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern IntPtr lp_step(int handle, double dt, double viewW, double viewH);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern IntPtr lp_get_snapshot_json(int handle, double viewW, double viewH);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern IntPtr lp_get_ui_json(int handle);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern IntPtr lp_click_button(int handle, [MarshalAs(UnmanagedType.LPUTF8Str)] string actionOrLabel);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern void lp_cycle_camera3d(int handle);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern IntPtr lp_restart(int handle);

    [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
    private static extern IntPtr lp_render_3d_bgra(int handle, int width, int height);
}
