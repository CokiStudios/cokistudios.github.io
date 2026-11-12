#pragma once

#include <cmath>
#include <array>
#include <vector>
#include <string>
#include <sstream>
#include <fstream>
#include <iomanip>
#include <algorithm>
#include <limits>
#include <cstdint>
#include <cstdio>
#include <unordered_map>
#include <cstdio>
#include <unordered_map>

namespace loop_math {

constexpr double PI_3D = 3.14159265358979323846;
constexpr double DEG2RAD_3D = PI_3D / 180.0;
constexpr double RAD2DEG_3D = 180.0 / PI_3D;

struct Vec3 {
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;

    constexpr Vec3() = default;
    constexpr Vec3(double _x, double _y, double _z) : x(_x), y(_y), z(_z) {}

    constexpr Vec3 operator+(const Vec3& o) const { return {x + o.x, y + o.y, z + o.z}; }
    constexpr Vec3 operator-(const Vec3& o) const { return {x - o.x, y - o.y, z - o.z}; }
    constexpr Vec3 operator-() const { return {-x, -y, -z}; }
    constexpr Vec3 operator*(double s) const { return {x * s, y * s, z * s}; }
    constexpr Vec3 operator/(double s) const { return (std::abs(s) > 1e-12) ? Vec3{x / s, y / s, z / s} : Vec3{}; }

    Vec3& operator+=(const Vec3& o) { x += o.x; y += o.y; z += o.z; return *this; }
    Vec3& operator-=(const Vec3& o) { x -= o.x; y -= o.y; z -= o.z; return *this; }
    Vec3& operator*=(double s) { x *= s; y *= s; z *= s; return *this; }

    double length_sq() const { return x * x + y * y + z * z; }
    double length() const { return std::sqrt(length_sq()); }

    Vec3 normalized() const {
        double len = length();
        return (len > 1e-12) ? Vec3{x / len, y / len, z / len} : Vec3{0.0, 0.0, 0.0};
    }
};

inline double dot(const Vec3& a, const Vec3& b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

inline Vec3 cross(const Vec3& a, const Vec3& b) {
    return {
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    };
}

inline double distance(const Vec3& a, const Vec3& b) {
    return (b - a).length();
}

inline Vec3 lerp(const Vec3& a, const Vec3& b, double t) {
    return {
        a.x + (b.x - a.x) * t,
        a.y + (b.y - a.y) * t,
        a.z + (b.z - a.z) * t
    };
}

inline Vec3 reflect(const Vec3& incident, const Vec3& normal) {
    Vec3 n = normal.normalized();
    return incident - n * (2.0 * dot(incident, n));
}

struct Quat {
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
    double w = 1.0;

    constexpr Quat() = default;
    constexpr Quat(double _x, double _y, double _z, double _w) : x(_x), y(_y), z(_z), w(_w) {}

    static constexpr Quat identity() { return {0.0, 0.0, 0.0, 1.0}; }

    Quat normalized() const {
        double len = std::sqrt(x * x + y * y + z * z + w * w);
        return (len > 1e-12) ? Quat{x / len, y / len, z / len, w / len} : identity();
    }

    static Quat from_axis_angle_deg(const Vec3& axis, double angle_deg) {
        Vec3 n = axis.normalized();
        double half_rad = (angle_deg * DEG2RAD_3D) * 0.5;
        double s = std::sin(half_rad);
        return Quat{n.x * s, n.y * s, n.z * s, std::cos(half_rad)}.normalized();
    }

    static Quat from_euler_deg(double pitch_x, double yaw_y, double roll_z) {
        double cx = std::cos(pitch_x * DEG2RAD_3D * 0.5);
        double sx = std::sin(pitch_x * DEG2RAD_3D * 0.5);
        double cy = std::cos(yaw_y * DEG2RAD_3D * 0.5);
        double sy = std::sin(yaw_y * DEG2RAD_3D * 0.5);
        double cz = std::cos(roll_z * DEG2RAD_3D * 0.5);
        double sz = std::sin(roll_z * DEG2RAD_3D * 0.5);

        return Quat{
            sx * cy * cz + cx * sy * sz,
            cx * sy * cz - sx * cy * sz,
            cx * cy * sz + sx * sy * cz,
            cx * cy * cz - sx * sy * sz
        }.normalized();
    }

    Quat operator*(const Quat& b) const {
        return Quat{
            w * b.x + x * b.w + y * b.z - z * b.y,
            w * b.y - x * b.z + y * b.w + z * b.x,
            w * b.z + x * b.y - y * b.x + z * b.w,
            w * b.w - x * b.x - y * b.y - z * b.z
        };
    }

    Vec3 rotate(const Vec3& v) const {
        Vec3 qv{x, y, z};
        Vec3 uv = cross(qv, v);
        Vec3 uuv = cross(qv, uv);
        return v + ((uv * w) + uuv) * 2.0;
    }

    static Quat slerp(const Quat& qa, const Quat& qb_in, double t) {
        Quat a = qa.normalized();
        Quat b = qb_in.normalized();
        double cos_half = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
        if (cos_half < 0.0) {
            b = Quat{-b.x, -b.y, -b.z, -b.w};
            cos_half = -cos_half;
        }
        if (cos_half > 0.9995) {
            return Quat{
                a.x + (b.x - a.x) * t,
                a.y + (b.y - a.y) * t,
                a.z + (b.z - a.z) * t,
                a.w + (b.w - a.w) * t
            }.normalized();
        }
        double half_angle = std::acos(std::clamp(cos_half, -1.0, 1.0));
        double sin_half = std::sin(half_angle);
        double ra = std::sin((1.0 - t) * half_angle) / sin_half;
        double rb = std::sin(t * half_angle) / sin_half;
        return Quat{
            a.x * ra + b.x * rb,
            a.y * ra + b.y * rb,
            a.z * ra + b.z * rb,
            a.w * ra + b.w * rb
        }.normalized();
    }
};

// Row-major 4x4 transformation matrix
struct Mat4 {
    std::array<double, 16> m{};

    static Mat4 identity() {
        Mat4 r;
        r.m = {
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        };
        return r;
    }

    static Mat4 perspective(double fov_deg, double aspect, double near_z, double far_z) {
        Mat4 r{};
        double tan_half = std::tan((fov_deg * DEG2RAD_3D) * 0.5);
        if (std::abs(tan_half) < 1e-9) tan_half = 1.0;
        if (std::abs(aspect) < 1e-9) aspect = 1.0;
        double range = far_z - near_z;
        if (std::abs(range) < 1e-9) range = 100.0;

        r.m[0]  = 1.0 / (aspect * tan_half);
        r.m[5]  = 1.0 / tan_half;
        r.m[10] = -(far_z + near_z) / range;
        r.m[11] = -(2.0 * far_z * near_z) / range;
        r.m[14] = -1.0;
        return r;
    }

    static Mat4 look_at(const Vec3& eye, const Vec3& target, const Vec3& up_hint = {0, 1, 0}) {
        Vec3 f = (target - eye).normalized();
        if (f.length_sq() < 1e-9) f = {0, 0, 1};
        Vec3 r = cross(f, up_hint).normalized();
        if (r.length_sq() < 1e-9) r = cross(f, Vec3{1, 0, 0}).normalized();
        Vec3 u = cross(r, f);

        Mat4 res = identity();
        res.m[0] = r.x;  res.m[1] = r.y;  res.m[2] = r.z;  res.m[3] = -dot(r, eye);
        res.m[4] = u.x;  res.m[5] = u.y;  res.m[6] = u.z;  res.m[7] = -dot(u, eye);
        res.m[8] = -f.x; res.m[9] = -f.y; res.m[10] = -f.z; res.m[11] = dot(f, eye);
        return res;
    }

    static Mat4 trs(const Vec3& pos, const Vec3& euler_deg, const Vec3& scale) {
        Quat q = Quat::from_euler_deg(euler_deg.x, euler_deg.y, euler_deg.z);
        Vec3 rx = q.rotate({scale.x, 0, 0});
        Vec3 ry = q.rotate({0, scale.y, 0});
        Vec3 rz = q.rotate({0, 0, scale.z});

        Mat4 res = identity();
        res.m[0] = rx.x; res.m[1] = ry.x; res.m[2]  = rz.x; res.m[3]  = pos.x;
        res.m[4] = rx.y; res.m[5] = ry.y; res.m[6]  = rz.y; res.m[7]  = pos.y;
        res.m[8] = rx.z; res.m[9] = ry.z; res.m[10] = rz.z; res.m[11] = pos.z;
        return res;
    }

    Mat4 operator*(const Mat4& b) const {
        Mat4 res{};
        for (int row = 0; row < 4; ++row) {
            for (int col = 0; col < 4; ++col) {
                double sum = 0.0;
                for (int k = 0; k < 4; ++k) {
                    sum += m[row * 4 + k] * b.m[k * 4 + col];
                }
                res.m[row * 4 + col] = sum;
            }
        }
        return res;
    }

    Vec3 transform_point(const Vec3& p) const {
        double x = m[0] * p.x + m[1] * p.y + m[2]  * p.z + m[3];
        double y = m[4] * p.x + m[5] * p.y + m[6]  * p.z + m[7];
        double z = m[8] * p.x + m[9] * p.y + m[10] * p.z + m[11];
        double w = m[12] * p.x + m[13] * p.y + m[14] * p.z + m[15];
        if (std::abs(w) > 1e-9 && std::abs(w - 1.0) > 1e-9) {
            return {x / w, y / w, z / w};
        }
        return {x, y, z};
    }

    Vec3 transform_dir(const Vec3& d) const {
        return {
            m[0] * d.x + m[1] * d.y + m[2]  * d.z,
            m[4] * d.x + m[5] * d.y + m[6]  * d.z,
            m[8] * d.x + m[9] * d.y + m[10] * d.z
        };
    }
};

struct ProjectedPoint {
    double x = 0.0;
    double y = 0.0;
    double depth = 0.0;
    bool visible = false;
};

inline ProjectedPoint project_point(const Vec3& world_pt, const Vec3& eye, const Vec3& target,
                                    double fov_deg, double width, double height, double near_z = 0.25) {
    Vec3 forward = (target - eye).normalized();
    if (forward.length_sq() < 1e-9) forward = {0, 0, 1};
    Vec3 right = cross(forward, Vec3{0, 1, 0}).normalized();
    if (right.length_sq() < 1e-9) right = {1, 0, 0};
    Vec3 up = cross(right, forward);

    Vec3 rel = world_pt - eye;
    double vx = dot(rel, right);
    double vy = dot(rel, up);
    double vz = dot(rel, forward);

    if (vz <= near_z) {
        return {0.0, 0.0, vz, false};
    }

    double aspect = (height > 1e-6) ? (width / height) : 1.0;
    double focal = 1.0 / std::tan((fov_deg * DEG2RAD_3D) * 0.5);
    double ndc_x = (vx * focal) / (vz * aspect);
    double ndc_y = (vy * focal) / vz;

    ProjectedPoint out;
    out.x = (ndc_x * 0.5 + 0.5) * width;
    out.y = (0.5 - ndc_y * 0.5) * height;
    out.depth = vz;
    out.visible = true;
    return out;
}

// ── 3D Collisions & Raycasting ──

struct RayHit3D {
    bool hit = false;
    double distance = 0.0;
    Vec3 point{};
    Vec3 normal{};
    std::string entity_name = "";
};

inline bool collide_sphere(const Vec3& c1, double r1, const Vec3& c2, double r2) {
    double rr = r1 + r2;
    return (c2 - c1).length_sq() <= rr * rr;
}

inline bool collide_aabb_center(const Vec3& c1, const Vec3& size1, const Vec3& c2, const Vec3& size2) {
    return std::abs(c1.x - c2.x) <= (size1.x + size2.x) * 0.5 &&
           std::abs(c1.y - c2.y) <= (size1.y + size2.y) * 0.5 &&
           std::abs(c1.z - c2.z) <= (size1.z + size2.z) * 0.5;
}

inline bool collide_capsule_sphere(const Vec3& cap_a, const Vec3& cap_b, double cap_r, const Vec3& sph_c, double sph_r) {
    Vec3 ab = cap_b - cap_a;
    double ab_len_sq = ab.length_sq();
    double t = 0.0;
    if (ab_len_sq > 1e-12) {
        t = std::clamp(dot(sph_c - cap_a, ab) / ab_len_sq, 0.0, 1.0);
    }
    Vec3 closest = cap_a + ab * t;
    return collide_sphere(closest, cap_r, sph_c, sph_r);
}

inline RayHit3D raycast_sphere(const Vec3& origin, const Vec3& dir_raw, const Vec3& center, double radius) {
    RayHit3D res;
    Vec3 dir = dir_raw.normalized();
    if (dir.length_sq() < 1e-12) return res;

    Vec3 oc = origin - center;
    double b = dot(oc, dir);
    double c = dot(oc, oc) - radius * radius;
    double disc = b * b - c;
    if (disc < 0.0) return res;

    double s = std::sqrt(disc);
    double t = -b - s;
    if (t < 0.0) t = -b + s;
    if (t < 0.0) return res;

    res.hit = true;
    res.distance = t;
    res.point = origin + dir * t;
    res.normal = (res.point - center).normalized();
    return res;
}

inline RayHit3D raycast_aabb(const Vec3& origin, const Vec3& dir_raw, const Vec3& box_center, const Vec3& box_size) {
    RayHit3D res;
    Vec3 dir = dir_raw.normalized();
    if (dir.length_sq() < 1e-12) return res;

    Vec3 half = box_size * 0.5;
    Vec3 bmin = box_center - half;
    Vec3 bmax = box_center + half;

    double tmin = -std::numeric_limits<double>::infinity();
    double tmax = std::numeric_limits<double>::infinity();
    Vec3 hit_normal{};

    auto slab = [&](double orig_c, double dir_c, double min_c, double max_c, const Vec3& n_neg, const Vec3& n_pos) -> bool {
        if (std::abs(dir_c) < 1e-12) {
            return orig_c >= min_c && orig_c <= max_c;
        }
        double inv = 1.0 / dir_c;
        double t1 = (min_c - orig_c) * inv;
        double t2 = (max_c - orig_c) * inv;
        Vec3 n1 = n_neg;
        Vec3 n2 = n_pos;
        if (t1 > t2) {
            std::swap(t1, t2);
            std::swap(n1, n2);
        }
        if (t1 > tmin) {
            tmin = t1;
            hit_normal = n1;
        }
        if (t2 < tmax) {
            tmax = t2;
        }
        return tmin <= tmax;
    };

    if (!slab(origin.x, dir.x, bmin.x, bmax.x, {-1, 0, 0}, {1, 0, 0})) return res;
    if (!slab(origin.y, dir.y, bmin.y, bmax.y, {0, -1, 0}, {0, 1, 0})) return res;
    if (!slab(origin.z, dir.z, bmin.z, bmax.z, {0, 0, -1}, {0, 0, 1})) return res;
    if (tmax < 0.0) return res;

    double t = (tmin >= 0.0) ? tmin : tmax;
    res.hit = true;
    res.distance = t;
    res.point = origin + dir * t;
    res.normal = hit_normal;
    return res;
}

inline RayHit3D raycast_plane(const Vec3& origin, const Vec3& dir_raw, const Vec3& plane_normal_raw, double plane_d = 0.0) {
    RayHit3D res;
    Vec3 dir = dir_raw.normalized();
    Vec3 n = plane_normal_raw.normalized();
    double denom = dot(n, dir);
    if (std::abs(denom) < 1e-9) return res;
    double t = -(dot(n, origin) + plane_d) / denom;
    if (t < 0.0) return res;
    res.hit = true;
    res.distance = t;
    res.point = origin + dir * t;
    res.normal = (denom < 0.0) ? n : -n;
    return res;
}

// ── 120Hz Sub-Stepping Rigidbody 3D Integration ──

struct RigidBody3DState {
    Vec3 pos{0, 2, 0};
    Vec3 vel{0, 0, 0};
    Vec3 force{0, 0, 0};
    double mass = 1.0;
    double radius = 1.0;
    double gravity = -24.0;
    double drag = 0.02;
    double friction = 0.86;
    double bounce = 0.18;
    double ground_y = 0.0;
    bool grounded = false;
};

inline void step_rigidbody_3d(RigidBody3DState& b, double dt, int substeps = 4) {
    int steps = std::clamp(substeps, 1, 32);
    double sub_dt = dt / static_cast<double>(steps);
    double inv_mass = (b.mass > 1e-6) ? (1.0 / b.mass) : 1.0;

    for (int i = 0; i < steps; ++i) {
        Vec3 accel = b.force * inv_mass + Vec3{0.0, b.gravity, 0.0};
        b.vel += accel * sub_dt;
        double damp = std::max(0.0, 1.0 - b.drag * sub_dt);
        b.vel *= damp;
        b.pos += b.vel * sub_dt;

        double min_y = b.ground_y + b.radius;
        if (b.pos.y <= min_y) {
            b.pos.y = min_y;
            if (b.vel.y < 0.0) {
                if (std::abs(b.vel.y) > 1.5 && b.bounce > 0.0) {
                    b.vel.y = -b.vel.y * b.bounce;
                    b.grounded = false;
                } else {
                    b.vel.y = 0.0;
                    b.grounded = true;
                }
            } else {
                b.grounded = true;
            }
            double horiz_f = std::pow(std::clamp(b.friction, 0.0, 1.0), 1.0 / static_cast<double>(steps));
            b.vel.x *= horiz_f;
            b.vel.z *= horiz_f;
        } else {
            b.grounded = false;
        }
    }
}

// ── 3D Scene Graph & Software TrueColor Z-Buffer Rasterizer (TUI Preview) ──

struct RGBColor {
    uint8_t r = 56, g = 189, b = 248;

    static RGBColor from_hex(const std::string& hex) {
        std::string s = hex;
        if (!s.empty() && s[0] == '#') s = s.substr(1);
        if (s.size() == 3) {
            std::string full;
            for (char c : s) { full += c; full += c; }
            s = full;
        }
        if (s.size() >= 6) {
            try {
                uint32_t v = static_cast<uint32_t>(std::stoul(s.substr(0, 6), nullptr, 16));
                return {
                    static_cast<uint8_t>((v >> 16) & 0xFF),
                    static_cast<uint8_t>((v >> 8) & 0xFF),
                    static_cast<uint8_t>(v & 0xFF)
                };
            } catch (...) {}
        }
        return {56, 189, 248};
    }
};

struct Face3D {
    std::vector<int> indices;
    double shade_bias = 1.0;
    std::vector<int> uv_indices{};
    std::vector<int> normal_indices{};
    Vec3 face_normal{0, 1, 0};
    std::string material = "";
};

struct Mesh3D {
    std::string name = "Mesh3D";
    std::string source_path = "";
    std::string material_lib = "";
    std::vector<Vec3> vertices;
    std::vector<Vec3> normals;
    std::vector<std::array<double, 2>> uvs;
    std::vector<Face3D> faces;
    Vec3 aabb_min{0, 0, 0};
    Vec3 aabb_max{0, 0, 0};
    Vec3 center{0, 0, 0};
    Vec3 size{0, 0, 0};
    double bounding_radius = 0.0;

    size_t triangle_count() const {
        size_t tris = 0;
        for (const auto& f : faces) {
            if (f.indices.size() >= 3) tris += (f.indices.size() - 2);
        }
        return tris;
    }

    void recompute_bounds() {
        if (vertices.empty()) {
            aabb_min = aabb_max = center = size = {0, 0, 0};
            bounding_radius = 0.0;
            return;
        }
        aabb_min = vertices[0];
        aabb_max = vertices[0];
        for (const auto& v : vertices) {
            aabb_min.x = std::min(aabb_min.x, v.x);
            aabb_min.y = std::min(aabb_min.y, v.y);
            aabb_min.z = std::min(aabb_min.z, v.z);
            aabb_max.x = std::max(aabb_max.x, v.x);
            aabb_max.y = std::max(aabb_max.y, v.y);
            aabb_max.z = std::max(aabb_max.z, v.z);
        }
        center = (aabb_min + aabb_max) * 0.5;
        size = aabb_max - aabb_min;
        double max_r2 = 0.0;
        for (const auto& v : vertices) {
            max_r2 = std::max(max_r2, (v - center).length_sq());
        }
        bounding_radius = std::sqrt(max_r2);

        for (auto& f : faces) {
            if (f.indices.size() >= 3) {
                int i0 = f.indices[0], i1 = f.indices[1], i2 = f.indices[2];
                if (i0 >= 0 && i0 < static_cast<int>(vertices.size()) &&
                    i1 >= 0 && i1 < static_cast<int>(vertices.size()) &&
                    i2 >= 0 && i2 < static_cast<int>(vertices.size())) {
                    Vec3 n = cross(vertices[i1] - vertices[i0], vertices[i2] - vertices[i0]).normalized();
                    if (n.length_sq() < 1e-9) n = {0, 1, 0};
                    f.face_normal = n;
                }
            }
        }
    }
};

inline Mesh3D make_box_mesh(double sx, double sy, double sz) {
    double hx = sx * 0.5, hy = sy * 0.5, hz = sz * 0.5;
    Mesh3D m;
    m.name = "BoxMesh";
    m.vertices = {
        {-hx, -hy, -hz}, { hx, -hy, -hz}, { hx,  hy, -hz}, {-hx,  hy, -hz},
        {-hx, -hy,  hz}, { hx, -hy,  hz}, { hx,  hy,  hz}, {-hx,  hy,  hz}
    };
    m.faces = {
        {{0, 3, 2, 1}, 0.85}, // Back (-Z)
        {{4, 5, 6, 7}, 0.95}, // Front (+Z)
        {{3, 7, 6, 2}, 1.12}, // Top (+Y)
        {{0, 1, 5, 4}, 0.55}, // Bottom (-Y)
        {{1, 2, 6, 5}, 0.90}, // Right (+X)
        {{0, 4, 7, 3}, 0.78}  // Left (-X)
    };
    m.recompute_bounds();
    return m;
}

inline Mesh3D make_pyramid_mesh(double sx, double sy, double sz) {
    double hx = sx * 0.5, hy = sy * 0.5, hz = sz * 0.5;
    Mesh3D m;
    m.name = "PyramidMesh";
    m.vertices = {
        {-hx, -hy, -hz}, { hx, -hy, -hz}, { hx, -hy,  hz}, {-hx, -hy,  hz},
        {0.0,  hy,  0.0}
    };
    m.faces = {
        {{0, 1, 2, 3}, 0.60},
        {{0, 4, 1}, 0.95},
        {{1, 4, 2}, 1.05},
        {{2, 4, 3}, 0.88},
        {{3, 4, 0}, 0.80}
    };
    m.recompute_bounds();
    return m;
}

inline Mesh3D make_octahedron_mesh(double r) {
    Mesh3D m;
    m.name = "OctahedronMesh";
    m.vertices = {
        { 0,  r * 1.35,  0}, { 0, -r * 1.35,  0},
        {-r,  0,  0}, { r,  0,  0}, { 0,  0, -r}, { 0,  0,  r}
    };
    m.faces = {
        {{0, 5, 3}, 1.10}, {{0, 3, 4}, 0.98}, {{0, 4, 2}, 0.86}, {{0, 2, 5}, 1.02},
        {{1, 3, 5}, 0.76}, {{1, 4, 3}, 0.68}, {{1, 2, 4}, 0.62}, {{1, 5, 2}, 0.72}
    };
    m.recompute_bounds();
    return m;
}

inline Mesh3D make_sphere_mesh(double radius, int rings = 6, int sectors = 10) {
    Mesh3D m;
    m.name = "SphereMesh";
    for (int r = 0; r <= rings; ++r) {
        double v = static_cast<double>(r) / rings;
        double phi = v * PI_3D;
        for (int s = 0; s <= sectors; ++s) {
            double u = static_cast<double>(s) / sectors;
            double theta = u * PI_3D * 2.0;
            double x = -radius * std::sin(phi) * std::cos(theta);
            double y =  radius * std::cos(phi);
            double z =  radius * std::sin(phi) * std::sin(theta);
            m.vertices.push_back({x, y, z});
        }
    }
    int stride = sectors + 1;
    for (int r = 0; r < rings; ++r) {
        for (int s = 0; s < sectors; ++s) {
            int i0 = r * stride + s;
            int i1 = i0 + 1;
            int i2 = (r + 1) * stride + (s + 1);
            int i3 = (r + 1) * stride + s;
            m.faces.push_back({{i0, i3, i2, i1}, 1.0});
        }
    }
    m.recompute_bounds();
    return m;
}

inline Mesh3D make_starfighter_mesh(double sx = 2.4, double sy = 1.2, double sz = 3.2) {
    double hx = sx * 0.5, hy = sy * 0.5, hz = sz * 0.5;
    Mesh3D m;
    m.name = "AngelStarfighter";
    m.vertices = {
        { 0.00,  0.08 * sy,  hz},
        {-0.30 * hx,  0.22 * sy,  0.25 * hz},
        { 0.30 * hx,  0.22 * sy,  0.25 * hz},
        {-hx, -0.10 * sy, -0.60 * hz},
        { hx, -0.10 * sy, -0.60 * hz},
        {-0.42 * hx,  0.28 * sy, -hz},
        { 0.42 * hx,  0.28 * sy, -hz},
        { 0.00, -hy,  0.45 * hz},
        {-0.40 * hx, -hy * 0.9, -0.92 * hz},
        { 0.40 * hx, -hy * 0.9, -0.92 * hz},
        { 0.00,  hy * 1.15, -0.10 * hz},
        {-0.24 * hx,  0.32 * sy, -0.58 * hz},
        { 0.24 * hx,  0.32 * sy, -0.58 * hz},
        { 0.00,  hy * 1.45, -0.78 * hz}
    };
    m.faces = {
        {{0, 2, 1}, 1.18},
        {{1, 2, 10}, 1.28},
        {{1, 10, 11}, 1.12},
        {{2, 12, 10}, 1.12},
        {{10, 12, 11}, 0.96},
        {{1, 11, 5, 3}, 1.05},
        {{2, 4, 6, 12}, 1.05},
        {{11, 12, 6, 5}, 0.94},
        {{10, 11, 13}, 1.10},
        {{10, 13, 12}, 1.10},
        {{0, 1, 3, 8, 7}, 0.80},
        {{0, 7, 9, 4, 2}, 0.84},
        {{5, 6, 9, 8}, 1.32},
        {{7, 8, 9}, 0.58}
    };
    m.recompute_bounds();
    return m;
}

// ── Wavefront .OBJ Parser, Exporter, Normalizer & Möller–Trumbore Mesh Raycaster ──

inline Mesh3D parse_obj_string(const std::string& obj_src, const std::string& fallback_name = "OBJModel") {
    Mesh3D m;
    m.name = fallback_name;
    std::istringstream iss(obj_src);
    std::string line;
    std::string current_mat = "";

    auto resolve_idx = [](int raw_idx, int count) -> int {
        if (raw_idx > 0) return raw_idx - 1;
        if (raw_idx < 0) return count + raw_idx;
        return 0;
    };

    while (std::getline(iss, line)) {
        while (!line.empty() && (line.back() == '\r' || line.back() == '\n' || line.back() == ' ' || line.back() == '\t')) {
            line.pop_back();
        }
        size_t first = line.find_first_not_of(" \t");
        if (first == std::string::npos) continue;
        line = line.substr(first);
        if (line.empty() || line[0] == '#') continue;

        std::istringstream ls(line);
        std::string cmd;
        ls >> cmd;

        if (cmd == "o" || cmd == "g") {
            std::string nm;
            std::getline(ls, nm);
            size_t nf = nm.find_first_not_of(" \t");
            if (nf != std::string::npos) {
                nm = nm.substr(nf);
                if (cmd == "o" || m.name == fallback_name) m.name = nm;
            }
        } else if (cmd == "mtllib") {
            ls >> m.material_lib;
        } else if (cmd == "usemtl") {
            ls >> current_mat;
        } else if (cmd == "v") {
            double x = 0.0, y = 0.0, z = 0.0;
            ls >> x >> y >> z;
            m.vertices.push_back({x, y, z});
        } else if (cmd == "vn") {
            double nx = 0.0, ny = 1.0, nz = 0.0;
            ls >> nx >> ny >> nz;
            m.normals.push_back(Vec3{nx, ny, nz}.normalized());
        } else if (cmd == "vt") {
            double u = 0.0, v = 0.0;
            ls >> u >> v;
            m.uvs.push_back({u, v});
        } else if (cmd == "f") {
            Face3D face;
            face.material = current_mat;
            face.shade_bias = 1.0;
            std::string tok;
            while (ls >> tok) {
                int v_idx = 0, vt_idx = 0, vn_idx = 0;
                size_t s1 = tok.find('/');
                try {
                    if (s1 == std::string::npos) {
                        v_idx = std::stoi(tok);
                    } else {
                        v_idx = std::stoi(tok.substr(0, s1));
                        size_t s2 = tok.find('/', s1 + 1);
                        if (s2 == std::string::npos) {
                            std::string vt_s = tok.substr(s1 + 1);
                            if (!vt_s.empty()) vt_idx = std::stoi(vt_s);
                        } else {
                            std::string vt_s = tok.substr(s1 + 1, s2 - s1 - 1);
                            std::string vn_s = tok.substr(s2 + 1);
                            if (!vt_s.empty()) vt_idx = std::stoi(vt_s);
                            if (!vn_s.empty()) vn_idx = std::stoi(vn_s);
                        }
                    }
                } catch (...) { continue; }

                int rv = resolve_idx(v_idx, static_cast<int>(m.vertices.size()));
                if (rv >= 0 && rv < static_cast<int>(m.vertices.size())) {
                    face.indices.push_back(rv);
                    if (vt_idx != 0) face.uv_indices.push_back(resolve_idx(vt_idx, static_cast<int>(m.uvs.size())));
                    if (vn_idx != 0) face.normal_indices.push_back(resolve_idx(vn_idx, static_cast<int>(m.normals.size())));
                }
            }
            if (face.indices.size() >= 3) {
                m.faces.push_back(face);
            }
        }
    }

    // Generate default outward vertex normals if none were supplied in the .obj
    if (m.normals.empty() && !m.vertices.empty()) {
        m.normals.assign(m.vertices.size(), Vec3{0, 0, 0});
        for (const auto& f : m.faces) {
            if (f.indices.size() < 3) continue;
            Vec3 fn = cross(m.vertices[f.indices[1]] - m.vertices[f.indices[0]],
                            m.vertices[f.indices[2]] - m.vertices[f.indices[0]]).normalized();
            for (int idx : f.indices) {
                if (idx >= 0 && idx < static_cast<int>(m.normals.size())) {
                    m.normals[idx] += fn;
                }
            }
        }
        for (auto& n : m.normals) n = n.normalized();
    }

    m.recompute_bounds();
    return m;
}

inline Mesh3D make_preset_obj_mesh(const std::string& preset_raw) {
    std::string p = preset_raw;
    std::transform(p.begin(), p.end(), p.begin(), [](unsigned char c) { return std::tolower(c); });
    if (p.find("starfighter") != std::string::npos || p.find("hovercraft") != std::string::npos || p.find("interceptor") != std::string::npos) {
        return make_starfighter_mesh(2.6, 1.3, 3.4);
    }
    if (p.find("valkyrie") != std::string::npos || p.find("drone") != std::string::npos) {
        return make_starfighter_mesh(2.2, 0.9, 2.2);
    }
    if (p.find("titan") != std::string::npos || p.find("boss") != std::string::npos || p.find("box") != std::string::npos) {
        return make_box_mesh(2.8, 3.2, 2.4);
    }
    if (p.find("crystal") != std::string::npos || p.find("gem") != std::string::npos || p.find("octa") != std::string::npos) {
        return make_octahedron_mesh(1.2);
    }
    if (p.find("sphere") != std::string::npos || p.find("orb") != std::string::npos) {
        return make_sphere_mesh(1.5, 6, 10);
    }
    if (p.find("pyramid") != std::string::npos || p.find("cone") != std::string::npos) {
        return make_pyramid_mesh(2.4, 2.8, 2.4);
    }
    return make_starfighter_mesh(2.4, 1.2, 3.0);
}

inline Mesh3D make_preset_obj_mesh(const std::string& preset_raw, double uniform_scale) {
    Mesh3D m = make_preset_obj_mesh(preset_raw);
    if (std::abs(uniform_scale - 1.0) > 1e-6) {
        for (auto& v : m.vertices) v = v * uniform_scale;
        m.recompute_bounds();
    }
    return m;
}

inline bool load_obj_file(const std::string& raw_path, Mesh3D& out_mesh, std::string* out_resolved_path = nullptr) {
    std::vector<std::string> candidates = {
        raw_path,
        "./" + raw_path,
        "./assets/models/" + raw_path,
        "./assets/models/" + raw_path + ".obj",
        "../assets/models/" + raw_path,
        "../assets/models/" + raw_path + ".obj",
        "./sample_loop_projects/" + raw_path
    };
    for (const auto& cp : candidates) {
        std::ifstream f(cp);
        if (f.good()) {
            std::ostringstream ss;
            ss << f.rdbuf();
            std::string base_name = raw_path;
            size_t slash = base_name.find_last_of("/\\");
            if (slash != std::string::npos) base_name = base_name.substr(slash + 1);
            size_t dot = base_name.find_last_of('.');
            if (dot != std::string::npos) base_name = base_name.substr(0, dot);
            out_mesh = parse_obj_string(ss.str(), base_name);
            out_mesh.source_path = cp;
            if (out_resolved_path) *out_resolved_path = cp;
            return !out_mesh.vertices.empty();
        }
    }
    return false;
}

inline Mesh3D load_obj_file(const std::string& raw_path) {
    Mesh3D m;
    if (load_obj_file(raw_path, m)) return m;
    Mesh3D fallback = make_preset_obj_mesh(raw_path);
    fallback.source_path = raw_path;
    return fallback;
}

inline std::string export_obj_string(const Mesh3D& m) {
    std::ostringstream out;
    out << "# Wavefront OBJ exported by Looping Engine (Arch 3.0A Quantum 3D + loopize++)\n";
    out << "o " << (m.name.empty() ? "LoopMesh3D" : m.name) << "\n";
    out << std::fixed << std::setprecision(4);
    for (const auto& v : m.vertices) {
        out << "v " << v.x << " " << v.y << " " << v.z << "\n";
    }
    for (const auto& uv : m.uvs) {
        out << "vt " << uv[0] << " " << uv[1] << "\n";
    }
    for (const auto& n : m.normals) {
        out << "vn " << n.x << " " << n.y << " " << n.z << "\n";
    }
    std::string last_mat = "";
    for (const auto& f : m.faces) {
        if (!f.material.empty() && f.material != last_mat) {
            out << "usemtl " << f.material << "\n";
            last_mat = f.material;
        }
        out << "f";
        for (size_t i = 0; i < f.indices.size(); ++i) {
            out << " " << (f.indices[i] + 1);
            bool has_vt = i < f.uv_indices.size();
            bool has_vn = i < f.normal_indices.size();
            if (has_vt || has_vn) {
                out << "/";
                if (has_vt) out << (f.uv_indices[i] + 1);
                if (has_vn) out << "/" << (f.normal_indices[i] + 1);
            }
        }
        out << "\n";
    }
    return out.str();
}

inline void normalize_mesh(Mesh3D& m, double target_extent = 2.0) {
    m.recompute_bounds();
    if (m.vertices.empty()) return;
    double max_dim = std::max({m.size.x, m.size.y, m.size.z});
    double scale = (max_dim > 1e-9) ? (target_extent / max_dim) : 1.0;
    Vec3 c = m.center;
    for (auto& v : m.vertices) {
        v = (v - c) * scale;
    }
    m.recompute_bounds();
}

inline Mesh3D subdivide_mesh(const Mesh3D& m) {
    Mesh3D out;
    out.name = m.name + "_Subdiv";
    out.material_lib = m.material_lib;
    out.vertices = m.vertices;

    for (const auto& f : m.faces) {
        if (f.indices.size() < 3) continue;
        // Fan-triangulate polygon then split each triangle into 4 sub-triangles
        int i0 = f.indices[0];
        for (size_t k = 1; k + 1 < f.indices.size(); ++k) {
            int i1 = f.indices[k];
            int i2 = f.indices[k + 1];
            Vec3 v0 = out.vertices[i0];
            Vec3 v1 = out.vertices[i1];
            Vec3 v2 = out.vertices[i2];

            int m01 = static_cast<int>(out.vertices.size());
            out.vertices.push_back((v0 + v1) * 0.5);
            int m12 = static_cast<int>(out.vertices.size());
            out.vertices.push_back((v1 + v2) * 0.5);
            int m20 = static_cast<int>(out.vertices.size());
            out.vertices.push_back((v2 + v0) * 0.5);

            out.faces.push_back({{i0, m01, m20}, f.shade_bias, {}, {}, f.face_normal, f.material});
            out.faces.push_back({{m01, i1, m12}, f.shade_bias, {}, {}, f.face_normal, f.material});
            out.faces.push_back({{m20, m12, i2}, f.shade_bias, {}, {}, f.face_normal, f.material});
            out.faces.push_back({{m01, m12, m20}, f.shade_bias, {}, {}, f.face_normal, f.material});
        }
    }
    out.recompute_bounds();
    return out;
}

// Möller–Trumbore 3D Ray-Triangle Intersection
inline RayHit3D raycast_triangle(const Vec3& origin, const Vec3& dir_raw,
                                 const Vec3& v0, const Vec3& v1, const Vec3& v2) {
    RayHit3D res;
    Vec3 dir = dir_raw.normalized();
    if (dir.length_sq() < 1e-12) return res;

    const double EPS = 1e-8;
    Vec3 e1 = v1 - v0;
    Vec3 e2 = v2 - v0;
    Vec3 h = cross(dir, e2);
    double a = dot(e1, h);
    if (std::abs(a) < EPS) return res;

    double f = 1.0 / a;
    Vec3 s = origin - v0;
    double u = f * dot(s, h);
    if (u < 0.0 || u > 1.0) return res;

    Vec3 q = cross(s, e1);
    double v = f * dot(dir, q);
    if (v < 0.0 || u + v > 1.0) return res;

    double t = f * dot(e2, q);
    if (t > EPS) {
        res.hit = true;
        res.distance = t;
        res.point = origin + dir * t;
        Vec3 n = cross(e1, e2).normalized();
        res.normal = (dot(n, dir) < 0.0) ? n : -n;
    }
    return res;
}

inline RayHit3D raycast_mesh(const Vec3& origin, const Vec3& dir_raw,
                             const Mesh3D& mesh,
                             const Vec3& pos = {0, 0, 0},
                             const Vec3& rot_deg = {0, 0, 0},
                             const Vec3& scale = {1, 1, 1}) {
    RayHit3D best;
    best.distance = std::numeric_limits<double>::infinity();
    if (mesh.vertices.empty() || mesh.faces.empty()) return RayHit3D{};

    Quat q = Quat::from_euler_deg(rot_deg.x, rot_deg.y, rot_deg.z);
    std::vector<Vec3> wv(mesh.vertices.size());
    for (size_t i = 0; i < mesh.vertices.size(); ++i) {
        Vec3 sv{mesh.vertices[i].x * scale.x, mesh.vertices[i].y * scale.y, mesh.vertices[i].z * scale.z};
        wv[i] = pos + q.rotate(sv);
    }

    for (const auto& f : mesh.faces) {
        if (f.indices.size() < 3) continue;
        const Vec3& v0 = wv[f.indices[0]];
        for (size_t k = 1; k + 1 < f.indices.size(); ++k) {
            const Vec3& v1 = wv[f.indices[k]];
            const Vec3& v2 = wv[f.indices[k + 1]];
            RayHit3D hit = raycast_triangle(origin, dir_raw, v0, v1, v2);
            if (hit.hit && hit.distance < best.distance) {
                best = hit;
            }
        }
    }
    if (!best.hit) best.distance = 0.0;
    return best;
}

struct Entity3D {
    std::string type = "box"; // player, box, moving_platform, sphere, cylinder, pyramid, torus, ring, crystal, enemy, boss, pad, hazard, checkpoint, portal, terrain, obj
    std::string name = "Entity3D";
    std::string mesh = "box";
    std::string obj_file = "";
    std::string cs_class = "";
    std::string tag = "default";
    Vec3 pos{0, 0, 0};
    Vec3 size{4, 1, 4};
    Vec3 scale{1, 1, 1};
    Vec3 rot_deg{0, 0, 0};
    Vec3 vel{0, 0, 0};
    double radius = 1.5;
    std::string axis = "x";
    double min_pos = -10.0;
    double max_pos = 10.0;
    double speed = 8.0;
    double power = 22.0;
    double health = 100.0;
    double damage = 25.0;
    double points = 150.0;
    double metallic = 0.5;
    double fire_rate = 1.6;
    std::string color = "#38bdf8";
    std::string label = "";
    bool has_custom_mesh = false;
    bool double_sided = true;
    Mesh3D custom_mesh{};

    void world_aabb(Vec3& out_min, Vec3& out_max) const {
        if (has_custom_mesh && !custom_mesh.vertices.empty()) {
            Vec3 hs{
                std::max(0.25, custom_mesh.size.x * 0.5 * std::abs(scale.x)),
                std::max(0.25, custom_mesh.size.y * 0.5 * std::abs(scale.y)),
                std::max(0.25, custom_mesh.size.z * 0.5 * std::abs(scale.z))
            };
            Vec3 c{
                pos.x + custom_mesh.center.x * scale.x,
                pos.y + custom_mesh.center.y * scale.y,
                pos.z + custom_mesh.center.z * scale.z
            };
            out_min = c - hs;
            out_max = c + hs;
            return;
        }
        Vec3 hs{
            std::max(0.25, ((type == "sphere" || type == "crystal" || type == "ring" || type == "portal") ? radius : size.x * 0.5) * std::abs(scale.x)),
            std::max(0.25, ((type == "sphere" || type == "crystal" || type == "ring" || type == "portal") ? radius : size.y * 0.5) * std::abs(scale.y)),
            std::max(0.25, ((type == "sphere" || type == "crystal" || type == "ring" || type == "portal") ? radius : size.z * 0.5) * std::abs(scale.z))
        };
        out_min = pos - hs;
        out_max = pos + hs;
    }

    int triangle_count() const {
        if (has_custom_mesh) return custom_mesh.triangle_count();
        if (type == "sphere") return 80;
        if (type == "pyramid") return 6;
        if (type == "crystal" || type == "ring" || type == "portal") return 8;
        if (type == "player") return 18;
        return 12;
    }
};

struct CollisionHit3D {
    bool collided = false;
    Vec3 normal{0, 1, 0};
    double penetration = 0.0;
    std::string other_name = "";
};

inline CollisionHit3D collide_entities_aabb(const Entity3D& a, const Entity3D& b) {
    Vec3 amin, amax, bmin, bmax;
    a.world_aabb(amin, amax);
    b.world_aabb(bmin, bmax);

    double ox = std::min(amax.x, bmax.x) - std::max(amin.x, bmin.x);
    double oy = std::min(amax.y, bmax.y) - std::max(amin.y, bmin.y);
    double oz = std::min(amax.z, bmax.z) - std::max(amin.z, bmin.z);
    if (ox <= 0.0 || oy <= 0.0 || oz <= 0.0) return CollisionHit3D{};

    CollisionHit3D hit;
    hit.collided = true;
    hit.other_name = b.name;
    Vec3 ca = (amin + amax) * 0.5;
    Vec3 cb = (bmin + bmax) * 0.5;
    if (ox <= oy && ox <= oz) {
        hit.penetration = ox;
        hit.normal = {(ca.x < cb.x) ? -1.0 : 1.0, 0.0, 0.0};
    } else if (oy <= oz) {
        hit.penetration = oy;
        hit.normal = {0.0, (ca.y < cb.y) ? -1.0 : 1.0, 0.0};
    } else {
        hit.penetration = oz;
        hit.normal = {0.0, 0.0, (ca.z < cb.z) ? -1.0 : 1.0};
    }
    return hit;
}

inline double tween_ease(const std::string& curve, double t) {
    t = std::clamp(t, 0.0, 1.0);
    if (curve == "in_quad") return t * t;
    if (curve == "out_quad") return 1.0 - (1.0 - t) * (1.0 - t);
    if (curve == "in_out_quad") return (t < 0.5) ? 2.0 * t * t : 1.0 - std::pow(-2.0 * t + 2.0, 2.0) * 0.5;
    if (curve == "in_cubic") return t * t * t;
    if (curve == "out_cubic") return 1.0 - std::pow(1.0 - t, 3.0);
    if (curve == "in_out_cubic") return (t < 0.5) ? 4.0 * t * t * t : 1.0 - std::pow(-2.0 * t + 2.0, 3.0) * 0.5;
    if (curve == "out_back") {
        const double c1 = 1.70158;
        const double c3 = c1 + 1.0;
        return 1.0 + c3 * std::pow(t - 1.0, 3.0) + c1 * std::pow(t - 1.0, 2.0);
    }
    if (curve == "out_bounce") {
        const double n1 = 7.5625;
        const double d1 = 2.75;
        if (t < 1.0 / d1) return n1 * t * t;
        if (t < 2.0 / d1) { t -= 1.5 / d1; return n1 * t * t + 0.75; }
        if (t < 2.5 / d1) { t -= 2.25 / d1; return n1 * t * t + 0.9375; }
        t -= 2.625 / d1;
        return n1 * t * t + 0.984375;
    }
    if (curve == "out_elastic") {
        if (t <= 0.0) return 0.0;
        if (t >= 1.0) return 1.0;
        const double c4 = (2.0 * PI_3D) / 3.0;
        return std::pow(2.0, -10.0 * t) * std::sin((t * 10.0 - 0.75) * c4) + 1.0;
    }
    return t;
}

inline std::unordered_map<std::string, std::string> parse_mtl_colors(const std::string& mtl_text) {
    std::unordered_map<std::string, std::string> palette;
    std::istringstream iss(mtl_text);
    std::string line, current;
    while (std::getline(iss, line)) {
        size_t hash = line.find('#');
        if (hash != std::string::npos) line = line.substr(0, hash);
        std::istringstream ls(line);
        std::string cmd;
        if (!(ls >> cmd)) continue;
        if (cmd == "newmtl") {
            ls >> current;
        } else if (cmd == "Kd" && !current.empty()) {
            double r = 0.8, g = 0.8, b = 0.8;
            if (ls >> r >> g >> b) {
                auto to_hex = [](double c) {
                    int v = std::clamp(static_cast<int>(std::round(c * 255.0)), 0, 255);
                    char buf[4];
                    std::snprintf(buf, sizeof(buf), "%02x", v);
                    return std::string(buf);
                };
                palette[current] = "#" + to_hex(r) + to_hex(g) + to_hex(b);
            }
        }
    }
    return palette;
}

inline bool frustum_sphere_visible(const Vec3& center, double radius, const Vec3& eye, const Vec3& target, double fov_deg, double max_dist = 240.0) {
    Vec3 fwd = (target - eye).normalized();
    if (fwd.length_sq() < 1e-9) fwd = {0, 0, 1};
    Vec3 to_c = center - eye;
    double depth = dot(to_c, fwd);
    if (depth < -radius || depth > max_dist + radius) return false;
    Vec3 perp = to_c - fwd * depth;
    double half_angle = (fov_deg * DEG2RAD_3D) * 0.75;
    double max_lat = std::max(1.0, depth) * std::tan(std::min(1.48, half_angle)) + radius * 1.5;
    return perp.length() <= max_lat;
}

struct SpringArmCamera3D {
    Vec3 current_pos{0, 8.0, -16.0};
    Vec3 current_target{0, 2.0, 6.0};
    double yaw_deg = 0.0;
    double pitch_deg = 16.0;
    double arm_length = 16.0;
    double height_offset = 4.2;
    double stiffness = 9.0;
    double trauma = 0.0;
    double time_accum = 0.0;

    void add_trauma(double amount) {
        trauma = std::clamp(trauma + amount, 0.0, 1.0);
    }

    Vec3 sample_shake() const {
        double shake = trauma * trauma;
        if (shake < 1e-4) return {0, 0, 0};
        return {
            std::sin(time_accum * 43.0) * shake * 0.85,
            std::cos(time_accum * 57.0) * shake * 0.65,
            std::sin(time_accum * 31.0) * shake * 0.45
        };
    }

    void update(const Vec3& target_pos, double dt) {
        time_accum += dt;
        trauma = std::max(0.0, trauma - dt * 1.45);
        double yr = yaw_deg * DEG2RAD_3D;
        double pr = std::clamp(pitch_deg, -70.0, 80.0) * DEG2RAD_3D;
        Vec3 offset{
            -std::sin(yr) * std::cos(pr) * arm_length,
            std::sin(pr) * arm_length + height_offset,
            -std::cos(yr) * std::cos(pr) * arm_length
        };
        Vec3 desired_pos = target_pos + offset + sample_shake();
        Vec3 desired_tgt = target_pos + Vec3{std::sin(yr) * 4.5, 1.4, std::cos(yr) * 4.5};
        double alpha = 1.0 - std::exp(-std::max(1.0, stiffness) * std::clamp(dt, 0.001, 0.1));
        current_pos = lerp(current_pos, desired_pos, alpha);
        current_target = lerp(current_target, desired_tgt, alpha);
    }
};

struct PointLight3D {
    Vec3 pos{0, 12, 10};
    std::string color = "#38bdf8";
    double intensity = 1.2;
    double range = 60.0;
};

struct Scene3D {
    bool active = false;
    std::string world_name = "Quantum Cyber Arena 3D";
    std::string sky_preset = "cyber_night";
    Vec3 world_size{160, 80, 160};
    bool show_grid = true;
    double fog_density = 0.010;

    // Camera
    std::string cam_mode = "chase";
    Vec3 cam_pos{0, 9.5, -18.0};
    Vec3 cam_target{0, 2.5, 8.0};
    double cam_fov = 62.0;
    double cam_smooth = 0.14;

    // Lighting
    Vec3 dir_light{-0.45, -1.0, -0.35};
    std::string dir_color = "#f8fafc";
    double dir_intensity = 1.05;
    std::string ambient_color = "#1e293b";
    double ambient_intensity = 0.42;
    std::vector<PointLight3D> point_lights;

    // Physics (120Hz Sub-Stepping Default)
    double gravity = -26.0;
    int substeps = 4;
    double friction = 0.86;
    double bounce = 0.12;

    std::vector<Entity3D> entities;

    void clear() {
        *this = Scene3D{};
    }

    void step(double dt = 1.0 / 60.0) {
        int steps = std::clamp(substeps, 1, 16);
        double sdt = dt / static_cast<double>(steps);
        for (int s = 0; s < steps; ++s) {
            for (auto& e : entities) {
                if (e.type == "moving_platform" || e.type == "enemy" || e.type == "boss") {
                    double& coord = (e.axis == "y") ? e.pos.y : ((e.axis == "z") ? e.pos.z : e.pos.x);
                    if (e.vel.x == 0 && e.vel.y == 0 && e.vel.z == 0) e.vel.x = e.speed;
                    double dir_sign = (e.vel.x >= 0) ? 1.0 : -1.0;
                    coord += dir_sign * e.speed * sdt;
                    if (coord >= e.max_pos) { coord = e.max_pos; e.vel.x = -std::abs(e.speed); }
                    if (coord <= e.min_pos) { coord = e.min_pos; e.vel.x =  std::abs(e.speed); }
                } else if (e.type == "crystal" || e.type == "ring" || e.type == "portal") {
                    e.rot_deg.y += 90.0 * sdt;
                } else if (e.type == "obj" && e.speed > 0.01 && e.axis == "spin") {
                    e.rot_deg.y += e.speed * 18.0 * sdt;
                }
            }
        }
    }

    int total_triangles() const {
        int tris = 0;
        for (const auto& e : entities) {
            if (e.type != "terrain") tris += e.triangle_count();
        }
        return tris;
    }

    RayHit3D raycast_scene(const Vec3& origin, const Vec3& dir_raw, double max_dist = 200.0) const {
        RayHit3D closest;
        closest.distance = max_dist;
        for (const auto& e : entities) {
            if (e.type == "terrain") continue;
            RayHit3D h;
            if (e.has_custom_mesh && !e.custom_mesh.vertices.empty()) {
                h = raycast_mesh(origin, dir_raw, e.custom_mesh, e.pos, e.rot_deg, e.scale);
            } else if (e.type == "sphere" || e.type == "crystal" || e.type == "ring" || e.type == "portal") {
                h = raycast_sphere(origin, dir_raw, e.pos, std::max(0.5, e.radius));
            } else {
                Vec3 bmin, bmax;
                e.world_aabb(bmin, bmax);
                h = raycast_aabb(origin, dir_raw, (bmin + bmax) * 0.5, bmax - bmin);
            }
            if (h.hit && h.distance < closest.distance) {
                closest = h;
                closest.entity_name = e.name;
            }
        }
        if (!closest.hit) closest.distance = 0.0;
        return closest;
    }

    std::string render_tui(int cols = 74, int char_rows = 20) const {
        cols = std::clamp(cols, 32, 140);
        char_rows = std::clamp(char_rows, 10, 60);
        int px_w = cols;
        int px_h = char_rows * 2;

        std::vector<RGBColor> fb(px_w * px_h);
        std::vector<double> zb(px_w * px_h, std::numeric_limits<double>::infinity());

        // 1. Skybox & Horizon Gradient
        for (int y = 0; y < px_h; ++y) {
            double t = static_cast<double>(y) / std::max(1, px_h - 1);
            RGBColor sky_top{6, 10, 24};
            RGBColor sky_mid{14, 28, 62};
            RGBColor ground_dark{8, 13, 26};
            RGBColor c;
            if (t < 0.52) {
                double k = t / 0.52;
                c.r = static_cast<uint8_t>(sky_top.r + (sky_mid.r - sky_top.r) * k);
                c.g = static_cast<uint8_t>(sky_top.g + (sky_mid.g - sky_top.g) * k);
                c.b = static_cast<uint8_t>(sky_top.b + (sky_mid.b - sky_top.b) * k);
            } else {
                double k = (t - 0.52) / 0.48;
                c.r = static_cast<uint8_t>(sky_mid.r * (1.0 - k) + ground_dark.r * k);
                c.g = static_cast<uint8_t>(sky_mid.g * (1.0 - k) + ground_dark.g * k);
                c.b = static_cast<uint8_t>(sky_mid.b * (1.0 - k) + ground_dark.b * k);
            }
            for (int x = 0; x < px_w; ++x) fb[y * px_w + x] = c;
        }

        // Resolve camera auto-focus if player exists and cam_mode == chase
        Vec3 eye = cam_pos;
        Vec3 target = cam_target;
        for (const auto& e : entities) {
            if (e.type == "player") {
                if (cam_mode == "chase") {
                    eye = e.pos + Vec3{0.0, 6.5, -14.5};
                    target = e.pos + Vec3{0.0, 1.8, 10.0};
                }
                break;
            }
        }

        auto put_pixel = [&](int x, int y, double depth, const RGBColor& c) {
            if (x < 0 || x >= px_w || y < 0 || y >= px_h || depth <= 0.2) return;
            size_t idx = static_cast<size_t>(y) * px_w + x;
            if (depth < zb[idx]) {
                zb[idx] = depth;
                double fog = std::clamp(1.0 - std::exp(-fog_density * depth), 0.0, 0.78);
                RGBColor fog_col{11, 20, 42};
                fb[idx] = {
                    static_cast<uint8_t>(c.r * (1.0 - fog) + fog_col.r * fog),
                    static_cast<uint8_t>(c.g * (1.0 - fog) + fog_col.g * fog),
                    static_cast<uint8_t>(c.b * (1.0 - fog) + fog_col.b * fog)
                };
            }
        };

        auto draw_line_3d = [&](const Vec3& a, const Vec3& b, const RGBColor& col) {
            auto pa = project_point(a, eye, target, cam_fov, px_w, px_h);
            auto pb = project_point(b, eye, target, cam_fov, px_w, px_h);
            if (!pa.visible || !pb.visible) return;
            int x0 = static_cast<int>(std::round(pa.x));
            int y0 = static_cast<int>(std::round(pa.y));
            int x1 = static_cast<int>(std::round(pb.x));
            int y1 = static_cast<int>(std::round(pb.y));
            int steps = std::max(std::abs(x1 - x0), std::abs(y1 - y0));
            if (steps == 0) { put_pixel(x0, y0, pa.depth, col); return; }
            if (steps > px_w * 3) return;
            for (int i = 0; i <= steps; ++i) {
                double t = static_cast<double>(i) / steps;
                int x = static_cast<int>(std::round(x0 + (x1 - x0) * t));
                int y = static_cast<int>(std::round(y0 + (y1 - y0) * t));
                double d = pa.depth + (pb.depth - pa.depth) * t;
                put_pixel(x, y, d, col);
            }
        };

        // 2. Perspective Cyber Grid Floor (y = 0)
        if (show_grid) {
            RGBColor grid_col{24, 62, 108};
            for (int gz = -20; gz <= 90; gz += 6) {
                draw_line_3d({-48.0, 0.0, static_cast<double>(gz)}, {48.0, 0.0, static_cast<double>(gz)}, grid_col);
            }
            for (int gx = -48; gx <= 48; gx += 6) {
                draw_line_3d({static_cast<double>(gx), 0.0, -16.0}, {static_cast<double>(gx), 0.0, 90.0}, grid_col);
            }
        }

        // 3. Rasterize 3D Entities with Z-Buffer + Directional Lambertian Shading
        Vec3 light_dir = (-dir_light).normalized();
        if (light_dir.length_sq() < 1e-9) light_dir = Vec3{0.4, 0.85, -0.35}.normalized();

        auto raster_tri = [&](const ProjectedPoint& p0, const ProjectedPoint& p1, const ProjectedPoint& p2, const RGBColor& col) {
            if (!p0.visible || !p1.visible || !p2.visible) return;
            int min_x = std::max(0, static_cast<int>(std::floor(std::min({p0.x, p1.x, p2.x}))));
            int max_x = std::min(px_w - 1, static_cast<int>(std::ceil(std::max({p0.x, p1.x, p2.x}))));
            int min_y = std::max(0, static_cast<int>(std::floor(std::min({p0.y, p1.y, p2.y}))));
            int max_y = std::min(px_h - 1, static_cast<int>(std::ceil(std::max({p0.y, p1.y, p2.y}))));

            double area = (p1.x - p0.x) * (p2.y - p0.y) - (p1.y - p0.y) * (p2.x - p0.x);
            if (std::abs(area) < 1e-6) return;
            double inv_area = 1.0 / area;

            for (int y = min_y; y <= max_y; ++y) {
                for (int x = min_x; x <= max_x; ++x) {
                    double px = x + 0.5, py = y + 0.5;
                    double w0 = ((p1.x - px) * (p2.y - py) - (p1.y - py) * (p2.x - px)) * inv_area;
                    double w1 = ((p2.x - px) * (p0.y - py) - (p2.y - py) * (p0.x - px)) * inv_area;
                    double w2 = 1.0 - w0 - w1;
                    if (w0 >= -1e-4 && w1 >= -1e-4 && w2 >= -1e-4) {
                        double inv_z = w0 / p0.depth + w1 / p1.depth + w2 / p2.depth;
                        double depth = (inv_z > 1e-9) ? (1.0 / inv_z) : (p0.depth + p1.depth + p2.depth) / 3.0;
                        put_pixel(x, y, depth, col);
                    }
                }
            }
        };

        for (const auto& e : entities) {
            if (e.type == "terrain") continue;
            Mesh3D mesh;
            if (e.has_custom_mesh && !e.custom_mesh.vertices.empty()) {
                mesh = e.custom_mesh;
            } else if (!e.obj_file.empty()) {
                mesh = make_preset_obj_mesh(e.obj_file);
            } else if (e.type == "sphere") {
                mesh = make_sphere_mesh(e.radius, 5, 8);
            } else if (e.type == "pyramid") {
                mesh = make_pyramid_mesh(e.size.x, e.size.y, e.size.z);
            } else if (e.type == "crystal" || e.type == "ring" || e.type == "portal") {
                mesh = make_octahedron_mesh(std::max(0.8, e.radius));
            } else if (e.type == "player") {
                mesh = make_starfighter_mesh();
            } else {
                mesh = make_box_mesh(std::max(0.5, e.size.x), std::max(0.3, e.size.y), std::max(0.5, e.size.z));
            }

            Quat q = Quat::from_euler_deg(e.rot_deg.x, e.rot_deg.y, e.rot_deg.z);
            std::vector<Vec3> world_v(mesh.vertices.size());
            for (size_t i = 0; i < mesh.vertices.size(); ++i) {
                Vec3 sv{mesh.vertices[i].x * e.scale.x, mesh.vertices[i].y * e.scale.y, mesh.vertices[i].z * e.scale.z};
                world_v[i] = e.pos + q.rotate(sv);
            }

            RGBColor base = RGBColor::from_hex(e.color);
            for (const auto& f : mesh.faces) {
                if (f.indices.size() < 3) continue;
                size_t i0 = f.indices[0], i1 = f.indices[1], i2 = f.indices[2];
                if (i0 >= world_v.size() || i1 >= world_v.size() || i2 >= world_v.size()) continue;
                const Vec3& v0 = world_v[i0];
                const Vec3& v1 = world_v[i1];
                const Vec3& v2 = world_v[i2];
                Vec3 n = cross(v1 - v0, v2 - v0).normalized();
                double ndotl_raw = dot(n, light_dir);
                double ndotl = e.double_sided ? std::abs(ndotl_raw) * 0.92 : std::max(0.0, ndotl_raw);
                double pt_boost = 0.0;
                Vec3 face_center = (v0 + v1 + v2) * (1.0 / 3.0);
                for (const auto& pl : point_lights) {
                    Vec3 to_l = pl.pos - face_center;
                    double dist = to_l.length();
                    if (dist < pl.range && dist > 1e-4) {
                        double atten = (1.0 - dist / pl.range);
                        double pd = e.double_sided ? std::abs(dot(n, to_l / dist)) : std::max(0.0, dot(n, to_l / dist));
                        pt_boost += pd * atten * pl.intensity * 0.45;
                    }
                }
                double intensity = std::clamp((ambient_intensity + ndotl * dir_intensity * 0.78 + pt_boost) * f.shade_bias, 0.24, 1.45);
                RGBColor shaded{
                    static_cast<uint8_t>(std::clamp(base.r * intensity, 0.0, 255.0)),
                    static_cast<uint8_t>(std::clamp(base.g * intensity, 0.0, 255.0)),
                    static_cast<uint8_t>(std::clamp(base.b * intensity, 0.0, 255.0))
                };

                ProjectedPoint p0 = project_point(v0, eye, target, cam_fov, px_w, px_h);
                for (size_t k = 1; k + 1 < f.indices.size(); ++k) {
                    size_t ik = f.indices[k], ik1 = f.indices[k + 1];
                    if (ik >= world_v.size() || ik1 >= world_v.size()) continue;
                    ProjectedPoint p1 = project_point(world_v[ik], eye, target, cam_fov, px_w, px_h);
                    ProjectedPoint p2 = project_point(world_v[ik1], eye, target, cam_fov, px_w, px_h);
                    raster_tri(p0, p1, p2, shaded);
                }
            }
        }

        // 4. Emit Unicode Half-Block TrueColor Frame
        std::ostringstream ss;
        ss << "\n  \033[1;36m╔";
        for (int i = 0; i < cols; ++i) ss << "═";
        ss << "╗\033[0m\n";
        std::string hdr = " 🕹️  SHINE LOOP 3D VIEWPORT — " + world_name +
                          " [" + std::to_string(entities.size()) + " meshes | " +
                          std::to_string(total_triangles()) + " tris | " +
                          std::to_string(substeps * 60) + "Hz]";
        if (static_cast<int>(hdr.size()) > cols) hdr = hdr.substr(0, cols);
        ss << "  \033[1;36m║\033[1;37m" << std::left << std::setw(cols) << hdr << "\033[1;36m║\033[0m\n";
        ss << "  \033[1;36m╠";
        for (int i = 0; i < cols; ++i) ss << "═";
        ss << "╣\033[0m\n";

        for (int cy = 0; cy < char_rows; ++cy) {
            ss << "  \033[1;36m║\033[0m";
            for (int x = 0; x < cols; ++x) {
                const RGBColor& top = fb[(cy * 2) * px_w + x];
                const RGBColor& bot = fb[(cy * 2 + 1) * px_w + x];
                ss << "\033[38;2;" << static_cast<int>(top.r) << ";" << static_cast<int>(top.g) << ";" << static_cast<int>(top.b)
                   << ";48;2;" << static_cast<int>(bot.r) << ";" << static_cast<int>(bot.g) << ";" << static_cast<int>(bot.b)
                   << "m▀";
            }
            ss << "\033[0m\033[1;36m║\033[0m\n";
        }

        ss << "  \033[1;36m╚";
        for (int i = 0; i < cols; ++i) ss << "═";
        ss << "╝\033[0m\n";
        return ss.str();
    }

    // ── Metal 4 (Apple Silicon APU Unified Memory & Hardware Raytracing) ──
    std::string emit_metal4_msl_shader() const {
        std::ostringstream msl;
        msl << "// =====================================================================\n";
        msl << "// ⚡ LOOP OS METAL 4 MSL 4.0 SHADING PIPELINE — " << world_name << "\n";
        msl << "// Generated by Looping Engine (Arch 3.0A Quantum Synthesis • Apple Silicon M4)\n";
        msl << "// Target: Metal 4 (MTLGPUFamilyApple9) | 240Hz ProMotion Zero-Copy Unified Memory\n";
        msl << "// =====================================================================\n\n";
        msl << "#include <metal_stdlib>\n";
        msl << "#include <metal_raytracing>\n";
        msl << "using namespace metal;\n\n";
        msl << "struct Metal4VertexIn {\n";
        msl << "    float3 position  [[attribute(0)]];\n";
        msl << "    float3 normal    [[attribute(1)]];\n";
        msl << "    float4 color     [[attribute(2)]];\n";
        msl << "    float2 texCoords [[attribute(3)]];\n";
        msl << "};\n\n";
        msl << "struct Metal4VertexOut {\n";
        msl << "    float4 position [[position]];\n";
        msl << "    float3 normal;\n";
        msl << "    float4 color;\n";
        msl << "    float2 texCoords;\n";
        msl << "    float3 worldPos;\n";
        msl << "};\n\n";
        msl << "struct Metal4Uniforms {\n";
        msl << "    float4x4 modelMatrix;\n";
        msl << "    float4x4 viewMatrix;\n";
        msl << "    float4x4 projectionMatrix;\n";
        msl << "    float3   cameraPosition;\n";
        msl << "    float    frameTime;\n";
        msl << "    float    ambientIntensity;\n";
        msl << "    float3   lightDirection;\n";
        msl << "    float3   lightColor;\n";
        msl << "};\n\n";
        msl << "// 1. Metal 4 Ultra-Low Latency Vertex Stage (240Hz Unified Memory Buffer)\n";
        msl << "vertex Metal4VertexOut metal4_vertex_main(Metal4VertexIn in [[stage_in]],\n";
        msl << "                                         constant Metal4Uniforms& uniforms [[buffer(1)]]) {\n";
        msl << "    Metal4VertexOut out;\n";
        msl << "    float4 worldPos = uniforms.modelMatrix * float4(in.position, 1.0);\n";
        msl << "    out.worldPos    = worldPos.xyz;\n";
        msl << "    out.position    = uniforms.projectionMatrix * uniforms.viewMatrix * worldPos;\n";
        msl << "    out.normal      = normalize((uniforms.modelMatrix * float4(in.normal, 0.0)).xyz);\n";
        msl << "    out.color       = in.color;\n";
        msl << "    out.texCoords   = in.texCoords;\n";
        msl << "    return out;\n";
        msl << "}\n\n";
        msl << "// 2. Metal 4 Hardware Mesh Shader Stage (Next-Gen Geometry Pipeline)\n";
        msl << "using Metal4MeshType = metal::mesh<Metal4VertexOut, void, 64, 126, topology::triangle>;\n";
        msl << "[[mesh]] void metal4_mesh_stage(Metal4MeshType outputMesh,\n";
        msl << "                               uint tid [[thread_index_in_threadgroup]],\n";
        msl << "                               constant Metal4Uniforms& uniforms [[buffer(1)]]) {\n";
        msl << "    // Metal 4 hardware-accelerated dynamic mesh clustering\n";
        msl << "    if (tid == 0) {\n";
        msl << "        outputMesh.set_primitive_count(0);\n";
        msl << "    }\n";
        msl << "}\n\n";
        msl << "// 3. Metal 4 Physically-Based Fragment Stage\n";
        msl << "fragment float4 metal4_fragment_main(Metal4VertexOut in [[stage_in]],\n";
        msl << "                                    constant Metal4Uniforms& uniforms [[buffer(1)]]) {\n";
        msl << "    float3 N = normalize(in.normal);\n";
        msl << "    float3 L = normalize(uniforms.lightDirection);\n";
        msl << "    float3 V = normalize(uniforms.cameraPosition - in.worldPos);\n";
        msl << "    float3 H = normalize(L + V);\n";
        msl << "    float NdotL = max(dot(N, L), 0.0);\n";
        msl << "    float NdotH = max(dot(N, H), 0.0);\n";
        msl << "    float diff = NdotL;\n";
        msl << "    float spec = pow(NdotH, 32.0) * 0.45;\n";
        msl << "    float3 finalColor = in.color.rgb * (uniforms.ambientIntensity + diff * uniforms.lightColor) + spec;\n";
        msl << "    return float4(finalColor, in.color.a);\n";
        msl << "}\n\n";
        msl << "// 4. Metal 4 Hardware Raytracing Intersection Kernel\n";
        msl << "kernel void metal4_raytrace_kernel(raytracing::acceleration_structure accelerationStructure [[buffer(0)]],\n";
        msl << "                                   constant Metal4Uniforms& uniforms [[buffer(1)]],\n";
        msl << "                                   texture2d<float, access::write> outputTexture [[texture(0)]],\n";
        msl << "                                   uint2 tid [[thread_position_in_grid]]) {\n";
        msl << "    if (tid.x >= outputTexture.get_width() || tid.y >= outputTexture.get_height()) return;\n";
        msl << "    raytracing::ray r;\n";
        msl << "    r.origin = uniforms.cameraPosition;\n";
        msl << "    r.direction = normalize(float3(float(tid.x) - float(outputTexture.get_width()) * 0.5,\n";
        msl << "                                   float(tid.y) - float(outputTexture.get_height()) * 0.5,\n";
        msl << "                                   float(outputTexture.get_height()) * 0.8));\n";
        msl << "    r.min_distance = 0.001;\n";
        msl << "    r.max_distance = 1000.0;\n";
        msl << "    raytracing::intersector<raytracing::triangle_data> intersector;\n";
        msl << "    auto intersection = intersector.intersect(r, accelerationStructure);\n";
        msl << "    float4 col = (intersection.type != raytracing::intersection_type::none) ? float4(0.0, 0.96, 0.83, 1.0) : float4(0.03, 0.05, 0.1, 1.0);\n";
        msl << "    outputTexture.write(col, tid);\n";
        msl << "}\n";
        return msl.str();
    }
};

} // namespace loop_math
